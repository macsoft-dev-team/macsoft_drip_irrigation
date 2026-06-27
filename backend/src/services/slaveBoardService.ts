import { z } from "zod";
import { prisma } from "../db/prisma.js";
import { AppError } from "../lib/AppError.js";
import { fieldService } from "./fieldService.js";

const createSlaveSchema = z.object({
  deviceUid: z.string().min(2).max(100),
  name: z.string().min(1).max(150),
  modbusAddress: z.number().int().min(1).max(247).default(1)
});

const updateSlaveSchema = createSlaveSchema.partial().extend({
  status: z.enum(["active", "inactive"]).optional()
});

async function assertOwnership(auth: Express.Request["auth"], masterControllerId: bigint) {
  if (!auth) throw new AppError(401, "Authentication required", "authRequired");
  
  const master = await prisma.masterController.findUnique({
    where: { id: masterControllerId },
    include: { field: true }
  });
  
  if (!master) throw new AppError(404, "Master controller not found", "masterNotFound");
  
  if (auth.role === "farmer") {
    await fieldService.assertFarmerOwnsField(auth.farmerId!, master.fieldId);
  }
  return master;
}

export const slaveBoardService = {
  async listByMasterController(auth: Express.Request["auth"], masterControllerId: bigint) {
    await assertOwnership(auth, masterControllerId);
    
    return prisma.slaveBoard.findMany({
      where: { masterControllerId },
      include: { valves: true },
      orderBy: { modbusAddress: "asc" }
    });
  },

  async create(auth: Express.Request["auth"], masterControllerId: bigint, input: unknown) {
    await assertOwnership(auth, masterControllerId);
    const data = createSlaveSchema.parse(input);

    // Check if modbus address is already taken under this master controller
    const existing = await prisma.slaveBoard.findFirst({
      where: {
        masterControllerId,
        modbusAddress: data.modbusAddress
      }
    });

    if (existing) {
      throw new AppError(409, "Modbus address already in use on this controller", "modbusAddressConflict");
    }

    return prisma.slaveBoard.create({
      data: {
        masterControllerId,
        deviceUid: data.deviceUid,
        name: data.name,
        modbusAddress: data.modbusAddress,
        status: "active"
      }
    });
  },

  async update(auth: Express.Request["auth"], slaveBoardId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    
    const slave = await prisma.slaveBoard.findUnique({
      where: { id: slaveBoardId }
    });
    
    if (!slave) throw new AppError(404, "Slave board not found", "slaveBoardNotFound");
    await assertOwnership(auth, slave.masterControllerId);
    
    const data = updateSlaveSchema.parse(input);

    if (data.modbusAddress !== undefined && data.modbusAddress !== slave.modbusAddress) {
      const existing = await prisma.slaveBoard.findFirst({
        where: {
          masterControllerId: slave.masterControllerId,
          modbusAddress: data.modbusAddress,
          id: { not: slaveBoardId }
        }
      });
      if (existing) {
        throw new AppError(409, "Modbus address already in use on this controller", "modbusAddressConflict");
      }
    }

    return prisma.slaveBoard.update({
      where: { id: slaveBoardId },
      data
    });
  },

  async delete(auth: Express.Request["auth"], slaveBoardId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    
    const slave = await prisma.slaveBoard.findUnique({
      where: { id: slaveBoardId }
    });
    
    if (!slave) throw new AppError(404, "Slave board not found", "slaveBoardNotFound");
    await assertOwnership(auth, slave.masterControllerId);
    
    // Soft delete by marking inactive or hard delete if no valves attached
    const valvesCount = await prisma.valve.count({
      where: { slaveBoardId }
    });

    if (valvesCount > 0) {
      return prisma.slaveBoard.update({
        where: { id: slaveBoardId },
        data: { status: "inactive" }
      });
    }

    return prisma.slaveBoard.delete({
      where: { id: slaveBoardId }
    });
  }
};
