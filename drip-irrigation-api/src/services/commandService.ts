import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { uid } from "../lib/ids";
import { env } from "../config/env";
import { enqueueCommand } from "../queues/commandQueue";

type Action = "open" | "close";
type Source = "app" | "adminPanel" | "schedule" | "support" | "deviceHttp";

function addMinutes(minutes: number) {
  return new Date(Date.now() + minutes * 60_000);
}

function isMasterOnline(masterStatus: string) {
  return masterStatus === "online";
}

async function assertCommandVisible(auth: Express.Request["auth"], commandId: bigint) {
  if (!auth) throw new AppError(401, "Authentication required", "authRequired");

  const command = await prisma.command.findUnique({
    where: { id: commandId },
    include: { items: { include: { valve: true } }, masterController: true }
  });

  if (!command) throw new AppError(404, "Command not found", "commandNotFound");
  if (auth.role === "farmer" && command.farmerId !== auth.farmerId) {
    throw new AppError(403, "Forbidden", "forbidden");
  }

  return command;
}

export const commandService = {
  async createValveCommand(auth: Express.Request["auth"], valveId: bigint, action: Action, source: Source = "app") {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const valve = await prisma.valve.findUnique({
      where: { id: valveId },
      include: {
        zone: {
          include: {
            field: {
              include: {
                masterController: true
              }
            }
          }
        }
      }
    });

    if (!valve || valve.status === "disabled") {
      throw new AppError(404, "Valve not found", "valveNotFound");
    }

    const field = valve.zone.field;

    if (auth.role === "farmer" && field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    if (!field.masterController) {
      throw new AppError(409, "Field has no master controller", "missingMasterController");
    }

    const expiresAt = addMinutes(source === "schedule" ? env.SCHEDULE_COMMAND_EXPIRY_MINUTES : env.MANUAL_COMMAND_EXPIRY_MINUTES);
    const commandUid = uid("cmd");
    const master = field.masterController;

    const command = await prisma.command.create({
      data: {
        commandUid,
        farmerId: field.farmerId,
        fieldId: field.id,
        masterControllerId: master.id,
        requestedByUserId: auth.userId,
        targetType: "valve",
        targetId: valve.id,
        action,
        source,
        status: isMasterOnline(master.status) ? "queued" : "created",
        maxRetries: env.MAX_COMMAND_RETRIES,
        expiresAt,
        items: {
          create: {
            valveId: valve.id,
            sequenceNumber: 1,
            action,
            status: "pending"
          }
        }
      },
      include: {
        items: { include: { valve: true } },
        masterController: true
      }
    });

    if (isMasterOnline(master.status)) {
      await enqueueCommand(command.id);
    }

    return command;
  },

  async createZoneCommand(auth: Express.Request["auth"], zoneId: bigint, action: Action, source: Source = "app") {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const zone = await prisma.zone.findUnique({
      where: { id: zoneId },
      include: {
        valves: {
          where: { status: { not: "disabled" } },
          orderBy: { valveNumber: "asc" }
        },
        field: {
          include: {
            masterController: true
          }
        }
      }
    });

    if (!zone || zone.status !== "active") {
      throw new AppError(404, "Zone not found", "zoneNotFound");
    }

    if (auth.role === "farmer" && zone.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    if (!zone.field.masterController) {
      throw new AppError(409, "Field has no master controller", "missingMasterController");
    }

    if (zone.valves.length === 0) {
      throw new AppError(409, "Zone has no active valves", "zoneHasNoValves");
    }

    const expiresAt = addMinutes(source === "schedule" ? env.SCHEDULE_COMMAND_EXPIRY_MINUTES : env.MANUAL_COMMAND_EXPIRY_MINUTES);
    const commandUid = uid("cmd");
    const master = zone.field.masterController;

    const command = await prisma.command.create({
      data: {
        commandUid,
        farmerId: zone.field.farmerId,
        fieldId: zone.field.id,
        masterControllerId: master.id,
        requestedByUserId: auth.userId,
        targetType: "zone",
        targetId: zone.id,
        action,
        source,
        status: isMasterOnline(master.status) ? "queued" : "created",
        maxRetries: env.MAX_COMMAND_RETRIES,
        expiresAt,
        items: {
          create: zone.valves.map((valve, index) => ({
            valveId: valve.id,
            sequenceNumber: index + 1,
            action,
            status: "pending"
          }))
        }
      },
      include: {
        items: { include: { valve: true } },
        masterController: true
      }
    });

    if (isMasterOnline(master.status)) {
      await enqueueCommand(command.id);
    }

    return command;
  },

  async list(auth: Express.Request["auth"], filters: { status?: string } = {}) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    return prisma.command.findMany({
      where: {
        ...(auth.role === "farmer" ? { farmerId: auth.farmerId } : {}),
        ...(filters.status ? { status: filters.status as any } : {})
      },
      include: {
        items: { include: { valve: true } },
        masterController: true
      },
      orderBy: { id: "desc" },
      take: 100
    });
  },

  async get(auth: Express.Request["auth"], commandId: bigint) {
    return assertCommandVisible(auth, commandId);
  },

  async queuePendingForMaster(masterControllerId: bigint) {
    const commands = await prisma.command.findMany({
      where: {
        masterControllerId,
        status: "created",
        OR: [
          { expiresAt: null },
          { expiresAt: { gt: new Date() } }
        ]
      },
      take: 50,
      orderBy: { createdAt: "asc" }
    });

    for (const command of commands) {
      await prisma.command.update({
        where: { id: command.id },
        data: { status: "queued" }
      });
      await enqueueCommand(command.id);
    }

    return commands.length;
  }
};
