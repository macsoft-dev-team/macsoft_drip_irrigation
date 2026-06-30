import { z } from "zod";

export const createSlaveSchema = z.object({
  deviceUid: z.string().min(2).max(100),
  name: z.string().min(1).max(150),
  modbusAddress: z.number().int().min(1).max(247).default(1)
});

export const updateSlaveSchema = createSlaveSchema.partial().extend({
  status: z.enum(["active", "inactive"]).optional()
});
