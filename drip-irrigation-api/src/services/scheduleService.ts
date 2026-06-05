import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { fieldService } from "./fieldService";

const createScheduleSchema = z.object({
  fieldId: z.string(),
  name: z.string().min(1).max(150),
  targetType: z.enum(["valve", "zone"]),
  targetId: z.string(),
  startTime: z.string().regex(/^\d{2}:\d{2}$/),
  durationMinutes: z.number().int().positive(),
  repeatType: z.enum(["once", "daily", "weekly", "customDays"]).default("daily"),
  repeatDays: z.array(z.string()).optional(),
  timezone: z.string().default("Asia/Kolkata")
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
        repeatDays: data.repeatDays,
        timezone: data.timezone
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
        targetId: data.targetId ? BigInt(data.targetId) : undefined
      }
    });
  },

  async delete(auth: Express.Request["auth"], scheduleId: bigint) {
    return this.update(auth, scheduleId, { status: "deleted" });
  }
};
