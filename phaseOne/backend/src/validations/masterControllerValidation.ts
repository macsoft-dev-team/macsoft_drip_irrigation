import { z } from "zod";

export const createMasterSchema = z.object({
  deviceUid: z.string().min(2).max(100),
  imei: z.string().max(50).optional(),
  simNumber: z.string().max(30).optional(),
  firmwareVersion: z.string().max(50).optional(),
  connectionType: z.enum(["gsm4g", "gsm5g", "wifi", "loraGateway"]).default("gsm4g")
});

export const updateMasterSchema = createMasterSchema.partial().extend({
  status: z.enum(["online", "offline", "error", "disabled"]).optional()
});
