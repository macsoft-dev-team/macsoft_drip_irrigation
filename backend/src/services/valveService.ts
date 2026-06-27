import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { zoneService } from "./zoneService";
import { activityLogService } from "./activityLogService";

const createValveSchema = z.object({
  slaveBoardId: z.string().optional(),
  deviceUid: z.string().min(2).max(100),
  name: z.string().min(1).max(150),
  coilAddress: z.number().int().nonnegative().optional(),
  valveNumber: z.number().int().positive().optional()
});

const updateValveSchema = createValveSchema.partial().extend({
  status: z.enum(["open", "closed", "unknown", "error", "disabled"]).optional()
});

async function assertFarmerOwnsValve(farmerId: bigint, valveId: bigint) {
  const valve = await prisma.valve.findFirst({
    where: {
      id: valveId,
      zone: { field: { farmerId } }
    },
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

  if (!valve) throw new AppError(404, "Valve not found", "valveNotFound");
  return valve;
}

export const valveService = {
  assertFarmerOwnsValve,

  async listByZone(auth: Express.Request["auth"], zoneId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await zoneService.assertFarmerOwnsZone(auth.farmerId!, zoneId);
    }

    return prisma.valve.findMany({
      where: { zoneId },
      orderBy: { coilAddress: "asc" }
    });
  },

  async create(auth: Express.Request["auth"], zoneId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await zoneService.assertFarmerOwnsZone(auth.farmerId!, zoneId);
    }

    const data = createValveSchema.parse(input);

    let slaveBoardId: bigint;
    if (data.slaveBoardId) {
      slaveBoardId = BigInt(data.slaveBoardId);
      const zone = await prisma.zone.findUnique({
        where: { id: zoneId },
        include: {
          field: {
            include: {
              masterController: {
                include: { slaveBoards: true }
              }
            }
          }
        }
      });
      if (!zone || !zone.field.masterController) {
        throw new AppError(400, "Zone/Field must have a Master Controller before adding a valve", "masterControllerRequired");
      }
      const boardExists = zone.field.masterController.slaveBoards.some(sb => sb.id === slaveBoardId);
      if (!boardExists) {
        throw new AppError(400, "The specified Slave Board does not belong to this field", "invalidSlaveBoard");
      }
    } else {
      const zone = await prisma.zone.findUnique({
        where: { id: zoneId },
        include: {
          field: {
            include: {
              masterController: {
                include: { slaveBoards: true }
              }
            }
          }
        }
      });
      if (!zone || !zone.field.masterController) {
        throw new AppError(400, "Zone/Field must have a Master Controller before adding a valve", "masterControllerRequired");
      }

      const mc = zone.field.masterController;
      if (mc.slaveBoards.length > 0) {
        slaveBoardId = mc.slaveBoards[0].id;
      } else {
        const defaultSlave = await prisma.slaveBoard.create({
          data: {
            masterControllerId: mc.id,
            deviceUid: `slave-${mc.deviceUid}-001`,
            name: "Slave Board 1",
            status: "active"
          }
        });
        slaveBoardId = defaultSlave.id;
      }
    }

    let coilAddress = data.coilAddress;
    if (coilAddress === undefined && data.valveNumber !== undefined) {
      coilAddress = data.valveNumber - 1;
    }
    if (coilAddress === undefined) {
      throw new AppError(400, "coilAddress or valveNumber is required", "invalidInput");
    }

    const valve = await prisma.valve.create({
      data: {
        zoneId,
        slaveBoardId,
        deviceUid: data.deviceUid,
        name: data.name,
        coilAddress
      }
    });

    await activityLogService.log(auth.userId, "create", "valve", valve.id, { name: valve.name, coilAddress: valve.coilAddress });
    return valve;
  },

  async update(auth: Express.Request["auth"], valveId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role === "farmer") {
      await assertFarmerOwnsValve(auth.farmerId!, valveId);
    }

    const data = updateValveSchema.parse(input);
    let coilAddress = data.coilAddress;
    if (coilAddress === undefined && data.valveNumber !== undefined) {
      coilAddress = data.valveNumber - 1;
    }

    const { valveNumber, ...rest } = data; // strip valveNumber from rest mapping

    const valve = await prisma.valve.update({
      where: { id: valveId },
      data: {
        deviceUid: rest.deviceUid,
        name: rest.name,
        coilAddress,
        status: rest.status,
        slaveBoardId: rest.slaveBoardId ? BigInt(rest.slaveBoardId) : undefined
      }
    });

    await activityLogService.log(auth.userId, "update", "valve", valve.id, { name: valve.name, coilAddress: valve.coilAddress, status: valve.status });
    return valve;
  },

  async delete(auth: Express.Request["auth"], valveId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const valve = await this.update(auth, valveId, { status: "disabled" });
    await activityLogService.log(auth.userId, "delete", "valve", valveId);
    return valve;
  }
};
