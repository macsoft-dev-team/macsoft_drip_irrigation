import { createZoneSchema, updateZoneSchema, updateZoneValvesSchema } from "../validations/zoneValidation";
import { zoneRepository } from "../repositories/zoneRepository";
import { AppError } from "../lib/AppError";
import { fieldService } from "./fieldService";
import { commandService } from "./commandService";
import { activityLogService } from "./activityLogService";

async function assertFarmerOwnsZone(farmerId: bigint, zoneId: bigint) {
  const zone = await zoneRepository.findFirst({
    id: zoneId,
    field: { farmerId }
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

    return zoneRepository.listByField(fieldId);
  },

  async get(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const zone = await zoneRepository.findById(id);
    if (!zone) throw new AppError(404, "Zone not found", "zoneNotFound");
    if (auth.role === "farmer") {
      await assertFarmerOwnsZone(auth.farmerId!, id);
    }
    return zone;
  },

  async create(auth: Express.Request["auth"], fieldId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const data = createZoneSchema.parse(input);
    const zone = await zoneRepository.create({
      fieldId,
      name: data.name,
      description: data.description
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
    const zone = await zoneRepository.update(zoneId, data);

    await activityLogService.log(auth.userId, "update", "zone", zone.id, { name: zone.name, status: zone.status });
    return zone;
  },

  async delete(auth: Express.Request["auth"], zoneId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const zone = await this.update(auth, zoneId, { status: "inactive" });
    await activityLogService.log(auth.userId, "delete", "zone", zoneId);
    return zone;
  },

  async start(auth: Express.Request["auth"], id: bigint) {
    return commandService.createZoneCommand(auth, id, "open");
  },

  async stop(auth: Express.Request["auth"], id: bigint) {
    return commandService.createZoneCommand(auth, id, "close");
  },

  async updateValves(auth: Express.Request["auth"], id: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await assertFarmerOwnsZone(auth.farmerId!, id);
    }

    const data = updateZoneValvesSchema.parse(input);
    const valveIds = data.valveIds.map(BigInt);

    return zoneRepository.updateValves(id, valveIds);
  }
};
