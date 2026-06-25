import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { hashPassword } from "../lib/password";

const createUserSchema = z.object({
  name: z.string().min(2).max(150),
  phone: z.string().min(8).max(20),
  email: z.string().email().optional(),
  password: z.string().min(8),
  role: z.enum(["admin", "tenant_admin", "sales", "technician", "customer_service", "warehouse_manager", "distributor", "dealer", "farmer"]),
  hasWholesalePricing: z.boolean().default(false),
  belongsToDistributorId: z.string().optional(),
  belongsToDealerId: z.string().optional()
});

const updateUserSchema = z.object({
  name: z.string().min(2).max(150).optional(),
  email: z.string().email().optional(),
  role: z.enum(["admin", "tenant_admin", "sales", "technician", "customer_service", "warehouse_manager", "distributor", "dealer", "farmer"]).optional(),
  status: z.enum(["active", "blocked", "deleted"]).optional(),
  hasWholesalePricing: z.boolean().optional(),
  belongsToDistributorId: z.string().optional(),
  belongsToDealerId: z.string().optional()
});

export const userService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    if (auth.role === "admin" && !auth.distributorId && !auth.dealerId) {
      return prisma.user.findMany({
        include: { farmer: true, distributor: true, dealer: true },
        orderBy: { id: "desc" }
      });
    }

    // Tenant admin filters users belonging to their tenant
    const distributorId = auth.distributorId;
    const dealerId = auth.dealerId;

    return prisma.user.findMany({
      where: {
        OR: [
          ...(distributorId ? [{ belongsToDistributorId: distributorId }, { id: auth.userId }] : []),
          ...(dealerId ? [{ belongsToDealerId: dealerId }, { id: auth.userId }] : [])
        ]
      },
      include: { farmer: true, distributor: true, dealer: true },
      orderBy: { id: "desc" }
    });
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = createUserSchema.parse(input);

    const existing = await prisma.user.findFirst({
      where: {
        OR: [
          { phone: data.phone },
          ...(data.email ? [{ email: data.email }] : [])
        ]
      }
    });
    if (existing) {
      throw new AppError(409, "User already exists", "userExists");
    }

    let belongsToDistributorId: bigint | null = null;
    let belongsToDealerId: bigint | null = null;

    if (auth.role === "admin" && !auth.distributorId && !auth.dealerId) {
      // Platform admin can specify target tenant
      belongsToDistributorId = data.belongsToDistributorId ? BigInt(data.belongsToDistributorId) : null;
      belongsToDealerId = data.belongsToDealerId ? BigInt(data.belongsToDealerId) : null;
    } else {
      // Tenant admin can only create users belonging to their own tenant
      belongsToDistributorId = auth.distributorId || null;
      belongsToDealerId = auth.dealerId || null;
      // Tenant admin cannot create a platform admin
      if (data.role === "admin") {
        throw new AppError(403, "Tenant admins cannot create platform admins", "forbidden");
      }
    }

    const passwordHash = await hashPassword(data.password);

    return prisma.user.create({
      data: {
        name: data.name,
        phone: data.phone,
        email: data.email,
        passwordHash,
        role: data.role,
        hasWholesalePricing: data.hasWholesalePricing,
        belongsToDistributorId,
        belongsToDealerId
      }
    });
  },

  async update(auth: Express.Request["auth"], userId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const targetUser = await prisma.user.findUnique({
      where: { id: userId }
    });
    if (!targetUser) {
      throw new AppError(404, "User not found", "userNotFound");
    }

    // Tenant admin check
    if (auth.role !== "admin" || auth.distributorId || auth.dealerId) {
      const isSameDistributor = auth.distributorId && targetUser.belongsToDistributorId === auth.distributorId;
      const isSameDealer = auth.dealerId && targetUser.belongsToDealerId === auth.dealerId;
      const isSelf = targetUser.id === auth.userId;

      if (!isSameDistributor && !isSameDealer && !isSelf) {
        throw new AppError(403, "Forbidden", "forbidden");
      }
    }

    const data = updateUserSchema.parse(input);

    return prisma.user.update({
      where: { id: userId },
      data: {
        name: data.name,
        email: data.email,
        role: data.role,
        status: data.status,
        hasWholesalePricing: data.hasWholesalePricing,
        belongsToDistributorId: data.belongsToDistributorId ? BigInt(data.belongsToDistributorId) : undefined,
        belongsToDealerId: data.belongsToDealerId ? BigInt(data.belongsToDealerId) : undefined
      }
    });
  }
};
