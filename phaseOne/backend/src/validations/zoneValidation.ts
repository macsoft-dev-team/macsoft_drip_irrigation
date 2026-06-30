import { z } from "zod";

export const createZoneSchema = z.object({
  name: z.string().min(1).max(150),
  description: z.string().optional()
});

export const updateZoneSchema = createZoneSchema.partial().extend({
  status: z.enum(["active", "inactive"]).optional()
});

export const updateZoneValvesSchema = z.object({
  valveIds: z.array(z.string())
});
