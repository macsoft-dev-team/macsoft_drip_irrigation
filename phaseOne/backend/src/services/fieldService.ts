import { createFieldSchema, updateFieldSchema } from "../validations/fieldValidation";
import { fieldRepository } from "../repositories/fieldRepository";
import { AppError } from "../lib/AppError";
import { activityLogService } from "./activityLogService";

async function assertFarmerOwnsField(farmerId: bigint, fieldId: bigint) {
  const field = await fieldRepository.findFirst({ id: fieldId, farmerId });
  if (!field) throw new AppError(404, "Field not found", "fieldNotFound");
  return field;
}

export const fieldService = {
  assertFarmerOwnsField,

  async listFields(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (auth.role === "farmer") {
      return fieldRepository.listByFarmer(auth.farmerId!);
    }
    return fieldRepository.listAll();
  },

  async listByFarmer(auth: Express.Request["auth"], farmerId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (auth.role === "farmer" && auth.farmerId !== farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }
    return fieldRepository.listByFarmer(farmerId);
  },

  async createField(auth: Express.Request["auth"], farmerId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (auth.role === "farmer" && auth.farmerId !== farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = createFieldSchema.parse(input);

    const field = await fieldRepository.createField({
      farmerId,
      name: data.name,
      locationName: data.locationName,
      latitude: data.latitude,
      longitude: data.longitude,
      areaAcres: data.areaAcres
    });

    await activityLogService.log(auth.userId, "create", "field", field.id, { name: field.name });
    return field;
  },

  async getField(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (auth.role === "farmer") {
      await assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    return fieldRepository.findById(fieldId);
  },

  async updateField(auth: Express.Request["auth"], fieldId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (auth.role === "farmer") {
      await assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const data = updateFieldSchema.parse(input);

    const updated = await fieldRepository.updateField(fieldId, {
      name: data.name,
      locationName: data.locationName,
      latitude: data.latitude,
      longitude: data.longitude,
      areaAcres: data.areaAcres,
      status: data.status
    });

    await activityLogService.log(auth.userId, "update", "field", updated.id, { name: updated.name });
    return updated;
  },

  async deleteField(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const deleted = await this.updateField(auth, fieldId, { status: "inactive" });
    await activityLogService.log(auth.userId, "delete", "field", fieldId);
    return deleted;
  }
};
