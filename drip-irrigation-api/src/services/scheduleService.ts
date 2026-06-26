import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { fieldService } from "./fieldService";

const createScheduleSchema = z.object({
  fieldId: z.union([z.string(), z.number()]).transform(val => String(val)),
  name: z.string().min(1).max(150),
  targetType: z.enum(["valve", "zone"]).optional().default("zone"),
  targetId: z.union([z.string(), z.number()]).optional().default("0").transform(val => String(val)),
  startTime: z.string().regex(/^\d{2}:\d{2}$/),
  durationMinutes: z.number().int().positive(),
  repeatType: z.enum(["once", "daily", "weekly", "customDays"]).default("daily"),
  repeatDays: z.array(z.string()).nullish(),
  timezone: z.string().default("Asia/Kolkata"),
  scheduleType: z.string().optional().default("timeBased"),
  zoneIds: z.array(z.union([z.number(), z.string()])).nullish(),
  sequenceData: z.array(z.any()).nullish()
});

const updateScheduleSchema = createScheduleSchema.partial().extend({
  status: z.enum(["active", "paused", "deleted"]).optional()
});

export const scheduleService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    return prisma.irrigationSchedule.findMany({
      where: auth.role === "farmer" ? { farmerId: auth.farmerId } : {},
      orderBy: { id: "desc" }
    });
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth?.farmerId && auth?.role === "farmer") {
      throw new AppError(401, "Farmer account required", "farmerRequired");
    }
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const data = createScheduleSchema.parse(input);
    const fieldId = BigInt(data.fieldId);
    const farmerId = auth.role === "farmer" ? auth.farmerId! : (await prisma.field.findUniqueOrThrow({ where: { id: fieldId } })).farmerId;

    if (auth.role === "farmer") {
      await fieldService.assertFarmerOwnsField(auth.farmerId!, fieldId);
    }

    return prisma.irrigationSchedule.create({
      data: {
        farmerId,
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
        sequenceData: data.sequenceData ? data.sequenceData : undefined
      }
    });
  },

  async update(auth: Express.Request["auth"], scheduleId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const schedule = await prisma.irrigationSchedule.findUnique({ where: { id: scheduleId } });
    if (!schedule) throw new AppError(404, "Schedule not found", "scheduleNotFound");
    if (auth.role === "farmer" && schedule.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateScheduleSchema.parse(input);

    return prisma.irrigationSchedule.update({
      where: { id: scheduleId },
      data: {
        ...data,
        fieldId: data.fieldId ? BigInt(data.fieldId) : undefined,
        targetId: data.targetId ? BigInt(data.targetId) : undefined,
        repeatDays: data.repeatDays ?? undefined,
        zoneIds: data.zoneIds ? data.zoneIds.map(id => Number(id)) : undefined,
        sequenceData: data.sequenceData ? data.sequenceData : undefined
      }
    });
  },

  async pause(auth: Express.Request["auth"], scheduleId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const schedule = await prisma.irrigationSchedule.findUnique({ where: { id: scheduleId } });
    if (!schedule) throw new AppError(404, "Schedule not found", "scheduleNotFound");
    if (auth.role === "farmer" && schedule.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    return prisma.irrigationSchedule.update({
      where: { id: scheduleId },
      data: { status: "paused" }
    });
  },

  async resume(auth: Express.Request["auth"], scheduleId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const schedule = await prisma.irrigationSchedule.findUnique({ where: { id: scheduleId } });
    if (!schedule) throw new AppError(404, "Schedule not found", "scheduleNotFound");
    if (auth.role === "farmer" && schedule.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    return prisma.irrigationSchedule.update({
      where: { id: scheduleId },
      data: { status: "active" }
    });
  },

  async delete(auth: Express.Request["auth"], scheduleId: bigint) {
    return this.update(auth, scheduleId, { status: "deleted" });
  }
};
