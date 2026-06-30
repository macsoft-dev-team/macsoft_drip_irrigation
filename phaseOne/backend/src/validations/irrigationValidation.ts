import { z } from "zod";

export const startStopIrrigationSchema = z.object({
  targetType: z.enum(["valve", "zone", "master"]),
  targetId: z.string(),
  durationMinutes: z.number().int().positive().optional()
});
