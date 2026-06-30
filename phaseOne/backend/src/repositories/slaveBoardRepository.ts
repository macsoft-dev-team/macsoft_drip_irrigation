import { prisma } from "../db/prisma";

export const slaveBoardRepository = {
  async listByMaster(masterControllerId: bigint) {
    return prisma.slaveBoard.findMany({
      where: { masterControllerId },
      include: { valves: true },
      orderBy: { modbusAddress: "asc" }
    });
  },

  async findById(id: bigint) {
    return prisma.slaveBoard.findUnique({
      where: { id },
      include: { valves: true }
    });
  },

  async findFirst(where: any) {
    return prisma.slaveBoard.findFirst({
      where
    });
  },

  async create(data: any) {
    return prisma.slaveBoard.create({
      data
    });
  },

  async update(id: bigint, data: any) {
    return prisma.slaveBoard.update({
      where: { id },
      data
    });
  },

  async delete(id: bigint) {
    return prisma.slaveBoard.delete({
      where: { id }
    });
  },

  async countValves(slaveBoardId: bigint) {
    return prisma.valve.count({
      where: { slaveBoardId }
    });
  }
};
