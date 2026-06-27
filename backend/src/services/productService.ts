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
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const products = await prisma.product.findMany({
      where: { status: "active" },
      orderBy: { id: "asc" }
    });

    const user = await prisma.user.findUnique({
      where: { id: auth.userId }
    });

    const allowedWholesale =
      ["admin", "tenant_admin", "sales", "distributor"].includes(auth.role) ||
      (auth.role === "dealer" && user?.hasWholesalePricing === true);

    if (!allowedWholesale) {
      return products.map(p => {
        const { wholesalePrice, ...rest } = p;
        return rest;
      });
    }

    return products;
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
