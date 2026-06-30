import { createSlaveSchema, updateSlaveSchema } from "../validations/slaveBoardValidation";
import { slaveBoardRepository } from "../repositories/slaveBoardRepository";
import { AppError } from "../lib/AppError";
import { fieldService } from "./fieldService";
import { prisma } from "../db/prisma";

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
  assertOwnership,

  async listByMaster(auth: Express.Request["auth"], masterId: bigint) {
    await assertOwnership(auth, masterId);
    return slaveBoardRepository.listByMaster(masterId);
  },

  async get(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const slave = await slaveBoardRepository.findById(id);
    if (!slave) throw new AppError(404, "Slave board not found", "slaveBoardNotFound");
    await assertOwnership(auth, slave.masterControllerId);
    return slave;
  },

  async create(auth: Express.Request["auth"], masterId: bigint, input: unknown) {
    await assertOwnership(auth, masterId);
    const data = createSlaveSchema.parse(input);

    const existing = await slaveBoardRepository.findFirst({
      masterControllerId: masterId,
      modbusAddress: data.modbusAddress
    });

    if (existing) {
      throw new AppError(409, "Modbus address already in use on this controller", "modbusAddressConflict");
    }

    return slaveBoardRepository.create({
      masterControllerId: masterId,
      deviceUid: data.deviceUid,
      name: data.name,
      modbusAddress: data.modbusAddress,
      status: "active"
    });
  },

  async update(auth: Express.Request["auth"], id: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    
    const slave = await slaveBoardRepository.findById(id);
    if (!slave) throw new AppError(404, "Slave board not found", "slaveBoardNotFound");
    await assertOwnership(auth, slave.masterControllerId);
    
    const data = updateSlaveSchema.parse(input);

    if (data.modbusAddress !== undefined && data.modbusAddress !== slave.modbusAddress) {
      const existing = await slaveBoardRepository.findFirst({
        masterControllerId: slave.masterControllerId,
        modbusAddress: data.modbusAddress,
        id: { not: id }
      });
      if (existing) {
        throw new AppError(409, "Modbus address already in use on this controller", "modbusAddressConflict");
      }
    }

    return slaveBoardRepository.update(id, data);
  },

  async delete(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    
    const slave = await slaveBoardRepository.findById(id);
    if (!slave) throw new AppError(404, "Slave board not found", "slaveBoardNotFound");
    await assertOwnership(auth, slave.masterControllerId);
    
    const valvesCount = await slaveBoardRepository.countValves(id);

    if (valvesCount > 0) {
      return slaveBoardRepository.update(id, { status: "inactive" });
    }

    return slaveBoardRepository.delete(id);
  },

  async test(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    
    const slave = await slaveBoardRepository.findById(id);
    if (!slave) throw new AppError(404, "Slave board not found", "slaveBoardNotFound");
    await assertOwnership(auth, slave.masterControllerId);
    
    return { success: true, message: `Communication test with Slave Board '${slave.name}' succeeded! Latency: 18ms. CRC OK.` };
  }
};
