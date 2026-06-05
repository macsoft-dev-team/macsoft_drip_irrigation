import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { uid } from "../lib/ids";

const createOrderSchema = z.object({
  farmerId: z.string().optional(),
  distributorId: z.string().optional(),
  platformFee: z.number().nonnegative().default(0),
  taxAmount: z.number().nonnegative().default(0),
  items: z.array(z.object({
    productId: z.string(),
    quantity: z.number().int().positive()
  })).min(1)
});

export const orderService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    return prisma.order.findMany({
      where:
        auth.role === "farmer"
          ? { farmerId: auth.farmerId }
          : auth.role === "distributor"
            ? { distributorId: auth.distributorId }
            : {},
      include: { items: { include: { product: true } } },
      orderBy: { id: "desc" }
    });
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const data = createOrderSchema.parse(input);

    const farmerId = auth.role === "farmer" ? auth.farmerId! : BigInt(data.farmerId!);
    const distributorId =
      auth.role === "distributor"
        ? auth.distributorId
        : data.distributorId
          ? BigInt(data.distributorId)
          : undefined;

    const products = await prisma.product.findMany({
      where: {
        id: { in: data.items.map((item) => BigInt(item.productId)) }
      }
    });

    if (products.length !== data.items.length) {
      throw new AppError(400, "One or more products are invalid", "invalidProducts");
    }

    const itemRows = data.items.map((item) => {
      const product = products.find((p) => p.id === BigInt(item.productId))!;
      const quantity = item.quantity;
      const unitPrice = Number(product.price);
      const totalPrice = unitPrice * quantity;
      return {
        productId: product.id,
        quantity,
        unitPrice,
        totalPrice
      };
    });

    const subtotal = itemRows.reduce((sum, item) => sum + item.totalPrice, 0);
    const totalAmount = subtotal + data.platformFee + data.taxAmount;

    return prisma.order.create({
      data: {
        farmerId,
        distributorId,
        orderNumber: uid("ord"),
        subtotal,
        platformFee: data.platformFee,
        taxAmount: data.taxAmount,
        totalAmount,
        items: {
          create: itemRows
        }
      },
      include: {
        items: { include: { product: true } }
      }
    });
  }
};
