import { z } from "zod";

export const createScheduleSchema = z.object({
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

export const updateScheduleSchema = createScheduleSchema.partial().extend({
  status: z.enum(["active", "paused", "deleted"]).optional()
});

export const updateScheduleStatusSchema = z.object({
  status: z.enum(["active", "paused", "deleted"])
});
