import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { commandTopic } from "../iot/topics";
import { publishMqtt } from "../iot/mqttClient";
import { env } from "../config/env";

export const commandDispatchService = {
  async dispatchCommand(commandId: bigint) {
    const command = await prisma.command.findUnique({
      where: { id: commandId },
      include: {
        masterController: true,
        items: {
          include: {
            valve: true
          },
          orderBy: { sequenceNumber: "asc" }
        }
      }
    });

    if (!command) throw new AppError(404, "Command not found", "commandNotFound");

    if (["acknowledged", "partialSuccess", "failed", "expired"].includes(command.status)) {
      return;
    }

    if (command.expiresAt && command.expiresAt <= new Date()) {
      await prisma.command.update({
        where: { id: command.id },
        data: { status: "expired", failedReason: "Command expired before dispatch" }
      });
      return;
    }

    if (command.masterController.status !== "online") {
      await prisma.command.update({
        where: { id: command.id },
        data: { status: "created" }
      });
      return;
    }

    const topic = commandTopic(command.farmerId, command.fieldId, command.masterController.deviceUid);

    const payload = {
      commandUid: command.commandUid,
      targetType: command.targetType,
      targetId: command.targetId.toString(),
      action: command.action,
      zoneValveDelaySeconds: env.ZONE_VALVE_DELAY_SECONDS,
      items: command.items.map((item) => ({
        commandItemId: item.id.toString(),
        valveId: item.valveId.toString(),
        valveNumber: item.valve.valveNumber,
        action: item.action,
        sequenceNumber: item.sequenceNumber
      })),
      issuedAt: new Date().toISOString(),
      expiresAt: command.expiresAt?.toISOString()
    };

    await publishMqtt(topic, payload);

    await prisma.command.update({
      where: { id: command.id },
      data: {
        status: "sent",
        sentAt: new Date(),
        retryCount: { increment: 1 }
      }
    });

    await prisma.commandItem.updateMany({
      where: { commandId: command.id, status: "pending" },
      data: {
        status: "sent",
        sentAt: new Date()
      }
    });
  }
};
