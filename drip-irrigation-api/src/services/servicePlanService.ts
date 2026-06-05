import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";

const createPlanSchema = z.object({
  farmerId: z.string(),
  planName: z.string().min(1).max(150),
  billingType: z.enum(["oneTime", "monthly", "yearly", "bundled"]).default("bundled"),
  feeAmount: z.number().nonnegative().default(0),
  remoteSupportEnabled: z.boolean().default(true),
  monitoringEnabled: z.boolean().default(true),
  startsAt: z.string(),
  endsAt: z.string().optional()
});

export const servicePlanService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    return prisma.farmerServicePlan.findMany({
      where: auth.role === "farmer" ? { farmerId: auth.farmerId } : {},
      orderBy: { id: "desc" }
    });
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth || !["admin", "distributor"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = createPlanSchema.parse(input);

    return prisma.farmerServicePlan.create({
      data: {
        farmerId: BigInt(data.farmerId),
        planName: data.planName,
        billingType: data.billingType,
        feeAmount: data.feeAmount,
        remoteSupportEnabled: data.remoteSupportEnabled,
        monitoringEnabled: data.monitoringEnabled,
        startsAt: new Date(data.startsAt),
        endsAt: data.endsAt ? new Date(data.endsAt) : undefined
      }
    });
  }
};
