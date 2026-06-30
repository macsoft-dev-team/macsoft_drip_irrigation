import { startStopIrrigationSchema } from "../validations/irrigationValidation";
import { irrigationRepository } from "../repositories/irrigationRepository";
import { AppError } from "../lib/AppError";
import { commandService } from "./commandService";

export const irrigationService = {
  async start(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const data = startStopIrrigationSchema.parse(input);
    const targetId = BigInt(data.targetId);

    if (data.targetType === "valve") {
      return commandService.createValveCommand(auth, targetId, "open");
    } else if (data.targetType === "zone") {
      return commandService.createZoneCommand(auth, targetId, "open");
    } else if (data.targetType === "master") {
      return commandService.createMotorCommand(auth, targetId, "open");
    }

    throw new AppError(400, "Invalid target type for irrigation start", "invalidInput");
  },

  async stop(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const data = startStopIrrigationSchema.parse(input);
    const targetId = BigInt(data.targetId);

    if (data.targetType === "valve") {
      return commandService.createValveCommand(auth, targetId, "close");
    } else if (data.targetType === "zone") {
      return commandService.createZoneCommand(auth, targetId, "close");
    } else if (data.targetType === "master") {
      return commandService.createMotorCommand(auth, targetId, "close");
    }

    throw new AppError(400, "Invalid target type for irrigation stop", "invalidInput");
  },

  async getStatus(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const recent = await irrigationRepository.listRecentCommands(20);
    return {
      activeCommands: recent.filter(c => c.status === "created" || c.status === "queued" || c.status === "sent"),
      timestamp: new Date()
    };
  },

  async getHistory(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    return irrigationRepository.listRecentCommands(50);
  }
};
