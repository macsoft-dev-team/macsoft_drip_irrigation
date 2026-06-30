import { createScheduleSchema, updateScheduleSchema, updateScheduleStatusSchema } from "../validations/scheduleValidation";
import { scheduleRepository } from "../repositories/scheduleRepository";
import { AppError } from "../lib/AppError";
import { fieldService } from "./fieldService";
import { prisma } from "../db/prisma";
import { activityLogService } from "./activityLogService";

export const scheduleService = {
  async listByField(auth: Express.Request["auth"], fieldId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }
    return scheduleRepository.listByField(fieldId);
  },

  async get(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const schedule = await scheduleRepository.findById(id);
    if (!schedule) throw new AppError(404, "Schedule not found", "scheduleNotFound");
    if (auth.role === "farmer" && schedule.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }
    return schedule;
  },

  async create(auth: Express.Request["auth"], fieldId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    const field = await prisma.field.findUnique({ where: { id: fieldId } });
    if (!field) throw new AppError(404, "Field not found", "fieldNotFound");

    const data = createScheduleSchema.parse(input);

    const schedule = await scheduleRepository.create({
      farmerId: field.farmerId,
      fieldId,
      name: data.name,
      targetType: data.targetType,
      targetId: BigInt(data.targetId),
      startTime: data.startTime,
      durationMinutes: data.durationMinutes,
      repeatType: data.repeatType,
      repeatDays: data.repeatDays ?? undefined,
      timezone: data.timezone,
      scheduleType: data.scheduleType,
      zoneIds: data.zoneIds ? data.zoneIds.map(id => Number(id)) : undefined,
      sequenceData: data.sequenceData ? data.sequenceData : undefined,
      status: "active"
    });

    await activityLogService.log(auth.userId, "create", "schedule", schedule.id, { name: schedule.name, targetType: schedule.targetType });
    return schedule;
  },

  async update(auth: Express.Request["auth"], id: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const schedule = await scheduleRepository.findById(id);
    if (!schedule) throw new AppError(404, "Schedule not found", "scheduleNotFound");

    if (auth.role === "farmer" && schedule.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateScheduleSchema.parse(input);

    const updated = await scheduleRepository.update(id, {
      name: data.name,
      targetType: data.targetType,
      targetId: data.targetId ? BigInt(data.targetId) : undefined,
      startTime: data.startTime,
      durationMinutes: data.durationMinutes,
      repeatType: data.repeatType,
      repeatDays: data.repeatDays ?? undefined,
      timezone: data.timezone,
      scheduleType: data.scheduleType,
      zoneIds: data.zoneIds ? data.zoneIds.map(zid => Number(zid)) : undefined,
      sequenceData: data.sequenceData ? data.sequenceData : undefined,
      status: data.status
    });

    await activityLogService.log(auth.userId, "update", "schedule", updated.id, { name: updated.name, status: updated.status });
    return updated;
  },

  async updateStatus(auth: Express.Request["auth"], id: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const schedule = await scheduleRepository.findById(id);
    if (!schedule) throw new AppError(404, "Schedule not found", "scheduleNotFound");

    if (auth.role === "farmer" && schedule.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateScheduleStatusSchema.parse(input);
    const updated = await scheduleRepository.update(id, { status: data.status });
    await activityLogService.log(auth.userId, "update", "schedule", updated.id, { status: updated.status });
    return updated;
  },

  async delete(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const schedule = await scheduleRepository.findById(id);
    if (!schedule) throw new AppError(404, "Schedule not found", "scheduleNotFound");

    if (auth.role === "farmer" && schedule.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const deleted = await scheduleRepository.delete(id);
    await activityLogService.log(auth.userId, "delete", "schedule", id);
    return deleted;
  }
};
