import { z } from "zod";

export const createValveSchema = z.object({
  deviceUid: z.string().min(2).max(100),
  name: z.string().min(1).max(150),
  coilAddress: z.number().int().nonnegative().optional(),
  valveNumber: z.number().int().positive().optional()
});

export const updateValveSchema = createValveSchema.partial().extend({
  status: z.enum(["open", "closed", "unknown", "error", "disabled"]).optional(),
  slaveBoardId: z.string().optional(),
  zoneId: z.string().nullable().optional()
});
