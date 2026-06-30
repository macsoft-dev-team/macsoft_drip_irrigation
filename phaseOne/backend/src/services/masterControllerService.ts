import { createMasterSchema, updateMasterSchema } from "../validations/masterControllerValidation";
import { masterControllerRepository } from "../repositories/masterControllerRepository";
import { AppError } from "../lib/AppError";
import { fieldService } from "./fieldService";
import { activityLogService } from "./activityLogService";

export const masterControllerService = {
  async createForField(auth: Express.Request["auth"], fieldId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const data = createMasterSchema.parse(input);
    
    const existing = await masterControllerRepository.findByFieldId(fieldId);
    if (existing) {
      throw new AppError(409, "Master controller already exists for this field", "masterExists");
    }

    return masterControllerRepository.createForField(fieldId, data);
  },

  async getByField(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    return masterControllerRepository.findByFieldId(fieldId);
  },

  async update(auth: Express.Request["auth"], masterControllerId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const master = await masterControllerRepository.findById(masterControllerId);
    if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");

    if (auth.role === "farmer" && master.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateMasterSchema.parse(input);

    return masterControllerRepository.update(masterControllerId, data);
  },

  async delete(auth: Express.Request["auth"], masterControllerId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const master = await masterControllerRepository.findById(masterControllerId);
    if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");

    if (auth.role === "farmer" && master.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    await masterControllerRepository.delete(masterControllerId);
    await activityLogService.log(auth.userId, "delete", "command" as any, masterControllerId);
    return { success: true, message: "Master controller deleted successfully." };
  },

  async restart(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const master = await masterControllerRepository.findById(id);
    if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");

    if (auth.role === "farmer" && master.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    await activityLogService.log(auth.userId, "trigger", "command" as any, id, { action: "restart" });
    return { success: true, message: `Restart request sent to Master Controller ${master.deviceUid}.` };
  },

  async sync(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const master = await masterControllerRepository.findById(id);
    if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");

    if (auth.role === "farmer" && master.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    await activityLogService.log(auth.userId, "trigger", "command" as any, id, { action: "sync" });
    return { success: true, message: `Config sync request sent to Master Controller ${master.deviceUid}.` };
  }
};
