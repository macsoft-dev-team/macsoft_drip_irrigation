import { prisma } from "../db/prisma";

export const valveRepository = {
  async listBySlaveBoard(slaveBoardId: bigint) {
    return prisma.valve.findMany({
      where: { slaveBoardId },
      include: { slaveBoard: { include: { masterController: true } } },
      orderBy: { coilAddress: "asc" }
    });
  },

  async findById(id: bigint) {
    return prisma.valve.findUnique({
      where: { id },
      include: { slaveBoard: { include: { masterController: { include: { field: true } } } } }
    });
  },

  async findFirst(where: any) {
    return prisma.valve.findFirst({
      where
    });
  },

  async create(data: any) {
    return prisma.valve.create({
      data
    });
  },

  async update(id: bigint, data: any) {
    return prisma.valve.update({
      where: { id },
      data
    });
  },

  async delete(id: bigint) {
    return prisma.valve.update({
      where: { id },
      data: { status: "disabled" }
    });
  }
};
