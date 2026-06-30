import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";

const upsertInventorySchema = z.object({
  productId: z.string(),
  quantity: z.number().int().nonnegative(),
  distributorId: z.string().optional(),
  dealerId: z.string().optional()
});

export const inventoryService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin", "sales", "distributor", "dealer"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    // Platform Admin sees all
    if (auth.role === "admin" && !auth.distributorId && !auth.dealerId) {
      return prisma.inventoryItem.findMany({
        include: { product: true, distributor: true, dealer: true }
      });
    }

    // Filter by distributor or dealer
    const distributorId = auth.distributorId;
    const dealerId = auth.dealerId;

    return prisma.inventoryItem.findMany({
      where: {
        OR: [
          ...(distributorId ? [{ distributorId }] : []),
          ...(dealerId ? [{ dealerId }] : [])
        ]
      },
      include: { product: true, distributor: true, dealer: true }
    });
  },

  async upsert(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin", "distributor", "dealer"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = upsertInventorySchema.parse(input);
    const productId = BigInt(data.productId);

    let targetDistributorId: bigint | null = null;
    let targetDealerId: bigint | null = null;

    if (auth.role === "admin" && !auth.distributorId && !auth.dealerId) {
      // Central admin can specify target tenant
      targetDistributorId = data.distributorId ? BigInt(data.distributorId) : null;
      targetDealerId = data.dealerId ? BigInt(data.dealerId) : null;
    } else {
      // Tenant admin/user can only upsert their own inventory
      targetDistributorId = auth.distributorId || null;
      targetDealerId = auth.dealerId || null;
    }

    const whereInput = {
      productId_distributorId: targetDistributorId ? { productId, distributorId: targetDistributorId } : undefined,
      productId_dealerId: targetDealerId ? { productId, dealerId: targetDealerId } : undefined
    };

    // If both null, it's central inventory. We can look for existing where both are null.
    let existingItem = null;
    if (!targetDistributorId && !targetDealerId) {
      existingItem = await prisma.inventoryItem.findFirst({
        where: { productId, distributorId: null, dealerId: null }
      });
    } else if (targetDistributorId) {
      existingItem = await prisma.inventoryItem.findUnique({
        where: { productId_distributorId: { productId, distributorId: targetDistributorId } }
      });
    } else if (targetDealerId) {
      existingItem = await prisma.inventoryItem.findUnique({
        where: { productId_dealerId: { productId, dealerId: targetDealerId } }
      });
    }

    if (existingItem) {
      return prisma.inventoryItem.update({
        where: { id: existingItem.id },
        data: { quantity: data.quantity }
      });
    } else {
      return prisma.inventoryItem.create({
        data: {
          productId,
          distributorId: targetDistributorId,
          dealerId: targetDealerId,
          quantity: data.quantity
        }
      });
    }
  }
};
