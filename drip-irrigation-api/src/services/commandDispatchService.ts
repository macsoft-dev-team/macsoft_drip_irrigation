import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { publishDeviceCommand } from "../iot/mqttUtils";

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

    await publishDeviceCommand(command);

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

