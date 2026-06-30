import { z } from "zod";
import { asyncHandler } from "../lib/asyncHandler";
import { ok } from "../lib/http";
import { deviceService } from "../services/deviceService";

const heartbeatSchema = z.object({
  firmwareVersion: z.string().optional(),
  signalStrength: z.number().int().optional(),
  batteryVoltage: z.number().optional(),
  powerSource: z.enum(["mainPower", "battery", "solar"]).optional(),
  tankLevel: z.number().optional(),
  motorStatus: z.string().optional()
}).passthrough();

const ackSchema = z.object({
  commandUid: z.string(),
  status: z.enum(["acknowledged", "partialSuccess", "failed"]),
  failedReason: z.string().optional(),
  items: z.array(z.object({
    valveId: z.string(),
    status: z.enum(["acknowledged", "failed", "timeout", "skipped"]),
    currentValveStatus: z.enum(["open", "closed", "unknown", "error", "disabled"]).optional(),
    failedReason: z.string().optional()
  })).default([])
}).passthrough();

export const deviceController = {
  heartbeat: asyncHandler(async (req, res) => {
    const result = await deviceService.recordHeartbeat(String(req.params.deviceUid), heartbeatSchema.parse(req.body));
    return ok(res, result);
  }),

  ack: asyncHandler(async (req, res) => {
    const result = await deviceService.recordAck(String(req.params.deviceUid), ackSchema.parse(req.body));
    return ok(res, result);
  })
};
