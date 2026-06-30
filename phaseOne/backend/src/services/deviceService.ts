import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { commandService } from "./commandService";
import { emitAdminEvent, emitFarmerEvent, emitFieldEvent } from "../realtime/socket";
import { configTopic } from "../iot/topics";
import { publishMqtt } from "../iot/mqttClient";

type HeartbeatInput = {
  firmwareVersion?: string;
  signalStrength?: number;
  batteryVoltage?: number;
  powerSource?: "mainPower" | "battery" | "solar";
  [key: string]: unknown;
};

type AckInput = {
  commandUid: string;
  status: "acknowledged" | "partialSuccess" | "failed";
  failedReason?: string;
  items: Array<{
    valveId: string;
    status: "acknowledged" | "failed" | "timeout" | "skipped";
    currentValveStatus?: "open" | "closed" | "unknown" | "error" | "disabled";
    failedReason?: string;
  }>;
  [key: string]: unknown;
};

type StatusInput = {
  valves: Array<{
    valveId: string;
    currentValveStatus: "open" | "closed" | "unknown" | "error" | "disabled";
  }>;
  [key: string]: unknown;
};

export const deviceService = {
  async recordHeartbeat(deviceUid: string, input: HeartbeatInput) {
    const master = await prisma.masterController.findUnique({
      where: { deviceUid },
      include: { field: true }
    });

    if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");

    const wasOffline = master.status !== "online";
    const now = new Date();
    const lastHeartbeat = master.lastHeartbeatAt;
    const isFirstHeartbeatToday = !lastHeartbeat || lastHeartbeat.toDateString() !== now.toDateString();

    const updated = await prisma.masterController.update({
      where: { id: master.id },
      data: {
        status: "online",
        lastHeartbeatAt: now,
        firmwareVersion: input.firmwareVersion ?? master.firmwareVersion,
        tankLevel: input.tankLevel !== undefined ? Number(input.tankLevel) : undefined,
        motorStatus: input.motorStatus !== undefined ? String(input.motorStatus) : undefined
      },
      include: { field: true }
    });

    await prisma.masterHeartbeat.create({
      data: {
        masterControllerId: master.id,
        signalStrength: input.signalStrength,
        batteryVoltage: input.batteryVoltage,
        powerSource: input.powerSource,
        firmwareVersion: input.firmwareVersion,
        rawPayload: input as any
      }
    });

    if (isFirstHeartbeatToday) {
      try {
        const zones = await prisma.zone.findMany({
          where: {
            fieldId: master.fieldId,
            status: "active"
          },
          include: {
            valves: {
              where: {
                slaveBoard: {
                  masterControllerId: master.id
                },
                status: { not: "disabled" }
              }
            }
          }
        });

        const configPayload = {
          fieldId: master.fieldId.toString(),
          masterControllerId: master.id.toString(),
          deviceUid: master.deviceUid,
          zones: zones.map((zone) => ({
            zoneId: zone.id.toString(),
            name: zone.name,
            valves: zone.valves.map((valve) => ({
              valveId: valve.id.toString(),
              coilAddress: valve.coilAddress,
              deviceUid: valve.deviceUid,
              name: valve.name
            }))
          }))
        };

        const topic = configTopic(master.field.farmerId, master.fieldId, master.deviceUid);
        await publishMqtt(topic, configPayload);
        console.log(`Successfully sent daily configuration to master controller ${master.deviceUid}`);
      } catch (configError) {
        console.error("Failed to query or send configuration to master controller", master.deviceUid, configError);
      }
    }

    if (wasOffline) {
      await commandService.queuePendingForMaster(master.id);
    }

    emitFieldEvent(updated.fieldId, "masterHeartbeat", {
      masterControllerId: updated.id.toString(),
      status: updated.status,
      lastHeartbeatAt: updated.lastHeartbeatAt,
      tankLevel: updated.tankLevel,
      motorStatus: updated.motorStatus
    });

    emitAdminEvent("masterHeartbeat", {
      masterControllerId: updated.id.toString(),
      status: updated.status,
      lastHeartbeatAt: updated.lastHeartbeatAt,
      tankLevel: updated.tankLevel,
      motorStatus: updated.motorStatus
    });

    return updated;
  },

  async recordAck(deviceUid: string, input: AckInput) {
    const master = await prisma.masterController.findUnique({
      where: { deviceUid },
      include: { field: true }
    });

    if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");

    const command = await prisma.command.findUnique({
      where: { commandUid: input.commandUid },
      include: { items: true }
    });

    if (!command) throw new AppError(404, "Command not found", "commandNotFound");

    if (command.masterControllerId !== master.id) {
      throw new AppError(403, "ACK device mismatch", "ackDeviceMismatch");
    }

    const now = new Date();

    await prisma.$transaction(async (tx) => {
      for (const item of input.items) {
        const valveId = BigInt(item.valveId);
        const existingItem = command.items.find((ci) => ci.valveId === valveId);
        if (!existingItem) continue;

        await tx.commandItem.update({
          where: { id: existingItem.id },
          data: {
            status: item.status,
            acknowledgedAt: item.status === "acknowledged" ? now : undefined,
            failedReason: item.failedReason
          }
        });

        if (item.currentValveStatus) {
          const valve = await tx.valve.findUnique({ where: { id: valveId } });
          if (valve) {
            await tx.valve.update({
              where: { id: valveId },
              data: {
                status: item.currentValveStatus,
                lastStatusAt: now
              }
            });

            await tx.valveStatusLog.create({
              data: {
                valveId,
                commandId: command.id,
                oldStatus: valve.status,
                newStatus: item.currentValveStatus,
                source: command.source === "schedule" ? "schedule" : "masterController",
                rawPayload: item as any
              }
            });
          }
        }
      }

      if (command.targetType === "motor" && (input.status === "acknowledged" || input.status === "partialSuccess")) {
        const newMotorStatus = command.action === "open" ? "on" : "off";
        await tx.masterController.update({
          where: { id: command.masterControllerId },
          data: { motorStatus: newMotorStatus }
        });
      }

      await tx.command.update({
        where: { id: command.id },
        data: {
          status: input.status,
          acknowledgedAt: input.status === "acknowledged" || input.status === "partialSuccess" ? now : undefined,
          failedReason: input.failedReason
        }
      });
    });

    const updated = await prisma.command.findUnique({
      where: { id: command.id },
      include: {
        items: { include: { valve: true } },
        masterController: true
      }
    });

    emitFarmerEvent(command.farmerId, "commandUpdated", updated);
    emitFieldEvent(command.fieldId, "commandUpdated", updated);
    emitAdminEvent("commandUpdated", updated);

    return updated;
  },

  async recordStatus(deviceUid: string, input: StatusInput) {
    const master = await prisma.masterController.findUnique({
      where: { deviceUid },
      include: { field: true }
    });

    if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");

    const now = new Date();

    for (const item of input.valves) {
      const valveId = BigInt(item.valveId);
      const valve = await prisma.valve.findUnique({
        where: { id: valveId },
        include: { slaveBoard: { include: { masterController: true } } }
      });

      if (!valve || valve.slaveBoard.masterController.fieldId !== master.fieldId) continue;

      await prisma.valve.update({
        where: { id: valveId },
        data: {
          status: item.currentValveStatus,
          lastStatusAt: now
        }
      });

      await prisma.valveStatusLog.create({
        data: {
          valveId,
          oldStatus: valve.status,
          newStatus: item.currentValveStatus,
          source: "masterController",
          rawPayload: item as any
        }
      });
    }

    // Update master controller motor status and tank level if present
    if (input.tankLevel !== undefined || input.motorStatus !== undefined) {
      const updatedMaster = await prisma.masterController.update({
        where: { id: master.id },
        data: {
          tankLevel: input.tankLevel !== undefined ? Number(input.tankLevel) : undefined,
          motorStatus: input.motorStatus !== undefined ? String(input.motorStatus) : undefined
        }
      });

      emitFieldEvent(master.fieldId, "masterHeartbeat", {
        masterControllerId: master.id.toString(),
        status: updatedMaster.status,
        lastHeartbeatAt: updatedMaster.lastHeartbeatAt,
        tankLevel: updatedMaster.tankLevel,
        motorStatus: updatedMaster.motorStatus
      });

      emitAdminEvent("masterHeartbeat", {
        masterControllerId: master.id.toString(),
        status: updatedMaster.status,
        lastHeartbeatAt: updatedMaster.lastHeartbeatAt,
        tankLevel: updatedMaster.tankLevel,
        motorStatus: updatedMaster.motorStatus
      });
    }

    emitFieldEvent(master.fieldId, "valveStatusUpdated", input);
    emitAdminEvent("valveStatusUpdated", input);

    return { ok: true };
  }
};
