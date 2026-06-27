import { z } from "zod";
import { prisma } from "../db/prisma.js";
import { AppError } from "../lib/AppError.js";
import { fieldService } from "./fieldService.js";
import { activityLogService } from "./activityLogService.js";

const createZoneSchema = z.object({
  name: z.string().min(1).max(150),
  description: z.string().optional()
});

const updateZoneSchema = createZoneSchema.partial().extend({
  status: z.enum(["active", "inactive"]).optional()
});

async function assertFarmerOwnsZone(farmerId: bigint, zoneId: bigint) {
  const zone = await prisma.zone.findFirst({
    where: {
      id: zoneId,
      field: { farmerId }
    },
    include: { field: true }
  });
  if (!zone) throw new AppError(404, "Zone not found", "zoneNotFound");
  return zone;
}

export const zoneService = {
  assertFarmerOwnsZone,

  async listByField(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    return prisma.zone.findMany({
      where: { fieldId },
      include: { valves: true },
      orderBy: { id: "asc" }
    });
  },

  async create(auth: Express.Request["auth"], fieldId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const data = createZoneSchema.parse(input);
    const zone = await prisma.zone.create({
      data: {
        fieldId,
        name: data.name,
        description: data.description
      }
    });

    await activityLogService.log(auth.userId, "create", "zone", zone.id, { name: zone.name });
    return zone;
  },

  async update(auth: Express.Request["auth"], zoneId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await assertFarmerOwnsZone(auth.farmerId!, zoneId);
    }

    const data = updateZoneSchema.parse(input);
    const zone = await prisma.zone.update({
      where: { id: zoneId },
      data
    });

    await activityLogService.log(auth.userId, "update", "zone", zone.id, { name: zone.name, status: zone.status });
    return zone;
  },

  async delete(auth: Express.Request["auth"], zoneId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const zone = await this.update(auth, zoneId, { status: "inactive" });
    await activityLogService.log(auth.userId, "delete", "zone", zoneId);
    return zone;
  }
};
