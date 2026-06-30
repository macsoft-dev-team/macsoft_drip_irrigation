import { monitoringRepository } from "../repositories/monitoringRepository";
import { AppError } from "../lib/AppError";
import { fieldService } from "./fieldService";

export const monitoringService = {
  async getFieldStatus(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const status = await monitoringRepository.getFieldStatus(fieldId);
    if (!status) throw new AppError(404, "Field not found", "fieldNotFound");
    return status;
  },

  async getTelemetry(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const field = await monitoringRepository.getFieldStatus(fieldId);
    if (!field || !field.masterController) {
      throw new AppError(404, "Master controller not found for this field", "masterNotFound");
    }

    return monitoringRepository.getTelemetry(field.masterController.id);
  },

  async getLogs(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    return monitoringRepository.getValveLogs(fieldId);
  }
};
