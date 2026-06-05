import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { zoneService } from "./zoneService";

const createValveSchema = z.object({
  deviceUid: z.string().min(2).max(100),
  name: z.string().min(1).max(150),
  valveNumber: z.number().int().positive()
});

const updateValveSchema = createValveSchema.partial().extend({
  status: z.enum(["open", "closed", "unknown", "error", "disabled"]).optional()
});

async function assertFarmerOwnsValve(farmerId: bigint, valveId: bigint) {
  const valve = await prisma.valve.findFirst({
    where: {
      id: valveId,
      zone: { field: { farmerId } }
    },
    include: {
      zone: {
        include: {
          field: {
            include: {
              masterController: true
            }
          }
        }
      }
    }
  });

  if (!valve) throw new AppError(404, "Valve not found", "valveNotFound");
  return valve;
}

export const valveService = {
  assertFarmerOwnsValve,

  async listByZone(auth: Express.Request["auth"], zoneId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await zoneService.assertFarmerOwnsZone(auth.farmerId!, zoneId);
    }

    return prisma.valve.findMany({
      where: { zoneId },
      orderBy: { valveNumber: "asc" }
    });
  },

  async create(auth: Express.Request["auth"], zoneId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await zoneService.assertFarmerOwnsZone(auth.farmerId!, zoneId);
    }

    const data = createValveSchema.parse(input);

    return prisma.valve.create({
      data: {
        zoneId,
        deviceUid: data.deviceUid,
        name: data.name,
        valveNumber: data.valveNumber
      }
    });
  },

  async update(auth: Express.Request["auth"], valveId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await assertFarmerOwnsValve(auth.farmerId!, valveId);
    }

    const data = updateValveSchema.parse(input);
    return prisma.valve.update({
      where: { id: valveId },
      data
    });
  },

  async delete(auth: Express.Request["auth"], valveId: bigint) {
    return this.update(auth, valveId, { status: "disabled" });
  }
};
