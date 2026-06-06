import { z } from "zod";
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

const statusSchema = z.object({
  valves: z.array(z.object({
    valveId: z.string(),
    currentValveStatus: z.enum(["open", "closed", "unknown", "error", "disabled"])
  })).default([]),
  tankLevel: z.number().optional(),
  motorStatus: z.string().optional()
}).passthrough();

function extractDeviceUid(topic: string) {
  const parts = topic.split("/");
  const masterIndex = parts.indexOf("master");
  return masterIndex >= 0 ? parts[masterIndex + 1] : undefined;
}

export async function handleMqttMessage(topic: string, rawPayload: string) {
  try {
    const deviceUid = extractDeviceUid(topic);
    if (!deviceUid) return;

    const payload = JSON.parse(rawPayload);

    if (topic.endsWith("/heartbeat")) {
      const data = heartbeatSchema.parse(payload);
      await deviceService.recordHeartbeat(deviceUid, data);
      return;
    }

    if (topic.endsWith("/ack")) {
      const data = ackSchema.parse(payload);
      await deviceService.recordAck(deviceUid, data);
      return;
    }

    if (topic.endsWith("/status")) {
      const data = statusSchema.parse(payload);
      await deviceService.recordStatus(deviceUid, data);
    }
  } catch (error) {
    console.error("MQTT message handling failed", { topic, rawPayload, error });
  }
}
