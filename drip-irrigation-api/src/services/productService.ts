import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";

const createProductSchema = z.object({
  name: z.string().min(1).max(200),
  sku: z.string().min(1).max(100),
  type: z.enum(["masterController", "valve", "accessory", "serviceFee"]),
  description: z.string().optional(),
  price: z.number().nonnegative()
});

export const productService = {
  async list() {
    return prisma.product.findMany({
      where: { status: "active" },
      orderBy: { id: "asc" }
    });
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth || !["admin", "distributor"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = createProductSchema.parse(input);

    return prisma.product.create({
      data
    });
  }
};
