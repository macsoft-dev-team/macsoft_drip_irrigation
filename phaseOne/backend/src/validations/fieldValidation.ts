import { z } from "zod";

export const createFieldSchema = z.object({
  name: z.string().min(1).max(150),
  locationName: z.string().max(255).optional(),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  areaAcres: z.number().optional()
});

export const updateFieldSchema = createFieldSchema.partial().extend({
  status: z.enum(["active", "inactive"]).optional()
});
