import { createValveSchema, updateValveSchema } from "../validations/valveValidation";
import { valveRepository } from "../repositories/valveRepository";
import { AppError } from "../lib/AppError";
import { prisma } from "../db/prisma";
import { commandService } from "./commandService";
import { activityLogService } from "./activityLogService";

async function assertFarmerOwnsValve(farmerId: bigint, valveId: bigint) {
  const valve = await valveRepository.findFirst({
    id: valveId,
    slaveBoard: { masterController: { field: { farmerId } } }
  });
  if (!valve) throw new AppError(404, "Valve not found", "valveNotFound");
  return valve;
}

export const valveService = {
  assertFarmerOwnsValve,

  async listBySlaveBoard(auth: Express.Request["auth"], slaveBoardId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const sb = await prisma.slaveBoard.findUnique({
      where: { id: slaveBoardId },
      include: { masterController: { include: { field: true } } }
    });
    if (!sb) throw new AppError(404, "Slave board not found", "slaveBoardNotFound");
    
    if (auth.role === "farmer" && sb.masterController.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    return valveRepository.listBySlaveBoard(slaveBoardId);
  },

  async get(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const valve = await valveRepository.findById(id);
    if (!valve) throw new AppError(404, "Valve not found", "valveNotFound");
    if (auth.role === "farmer" && valve.slaveBoard.masterController.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }
    return valve;
  },

  async create(auth: Express.Request["auth"], slaveBoardId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const slaveBoard = await prisma.slaveBoard.findUnique({
      where: { id: slaveBoardId },
      include: { masterController: { include: { field: true } } }
    });
    if (!slaveBoard) throw new AppError(404, "Slave board not found", "slaveBoardNotFound");
    if (auth.role === "farmer" && slaveBoard.masterController.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = createValveSchema.parse(input);

    let coilAddress = data.coilAddress;
    if (coilAddress === undefined && data.valveNumber !== undefined) {
      coilAddress = data.valveNumber - 1;
    }
    if (coilAddress === undefined) {
      throw new AppError(400, "coilAddress or valveNumber is required", "invalidInput");
    }

    // Check if the coil address is already taken on this slave board
    const existingValve = await prisma.valve.findFirst({
      where: {
        slaveBoardId,
        coilAddress
      }
    });
    if (existingValve) {
      throw new AppError(409, "Coil address already configured on this Slave Board", "coilAddressConflict");
    }

    const valve = await valveRepository.create({
      slaveBoardId,
      deviceUid: data.deviceUid,
      name: data.name,
      coilAddress
    });

    await activityLogService.log(auth.userId, "create", "valve", valve.id, { name: valve.name, coilAddress: valve.coilAddress });
    return valve;
  },

  async update(auth: Express.Request["auth"], id: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const currentValve = await valveRepository.findById(id);
    if (!currentValve) throw new AppError(404, "Valve not found", "valveNotFound");

    if (auth.role === "farmer" && currentValve.slaveBoard.masterController.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateValveSchema.parse(input);
    let coilAddress = data.coilAddress;
    if (coilAddress === undefined && data.valveNumber !== undefined) {
      coilAddress = data.valveNumber - 1;
    }

    const { valveNumber, ...rest } = data;

    if (coilAddress !== undefined) {
      const targetSlaveBoardId = rest.slaveBoardId ? BigInt(rest.slaveBoardId) : currentValve.slaveBoardId;
      const existingValve = await prisma.valve.findFirst({
        where: {
          slaveBoardId: targetSlaveBoardId,
          coilAddress,
          id: { not: id }
        }
      });
      if (existingValve) {
        throw new AppError(409, "Coil address already configured on this Slave Board", "coilAddressConflict");
      }
    }

    const updated = await valveRepository.update(id, {
      deviceUid: rest.deviceUid,
      name: rest.name,
      coilAddress,
      status: rest.status,
      slaveBoardId: rest.slaveBoardId ? BigInt(rest.slaveBoardId) : undefined,
      zoneId: rest.zoneId !== undefined ? (rest.zoneId ? BigInt(rest.zoneId) : null) : undefined
    });

    await activityLogService.log(auth.userId, "update", "valve", updated.id, { name: updated.name, coilAddress: updated.coilAddress, status: updated.status });
    return updated;
  },

  async delete(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const valve = await valveRepository.findById(id);
    if (!valve) throw new AppError(404, "Valve not found", "valveNotFound");

    if (auth.role === "farmer" && valve.slaveBoard.masterController.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const disabled = await valveRepository.delete(id);
    await activityLogService.log(auth.userId, "delete", "valve", id);
    return disabled;
  },

  async open(auth: Express.Request["auth"], id: bigint) {
    return commandService.createValveCommand(auth, id, "open");
  },

  async close(auth: Express.Request["auth"], id: bigint) {
    return commandService.createValveCommand(auth, id, "close");
  },

  async test(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const valve = await valveRepository.findById(id);
    if (!valve) throw new AppError(404, "Valve not found", "valveNotFound");

    if (auth.role === "farmer" && valve.slaveBoard.masterController.field.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    // Trigger test pulse: open command followed by simulated logs
    await commandService.createValveCommand(auth, id, "open");
    setTimeout(async () => {
      try {
        await commandService.createValveCommand(auth, id, "close");
      } catch (err) {
        console.error("Test pulse auto-close failed", err);
      }
    }, 5000);

    return { success: true, message: `5-second test pulse triggered on valve '${valve.name}'.` };
  }
};
