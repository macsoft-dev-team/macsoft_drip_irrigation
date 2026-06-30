import { prisma } from "../db/prisma";

export const fieldRepository = {
  async listAll() {
    return prisma.field.findMany({
      include: {
        masterController: true,
        zones: { include: { valves: { include: { slaveBoard: true } } } }
      },
      orderBy: { id: "desc" }
    });
  },

  async listByFarmer(farmerId: bigint) {
    return prisma.field.findMany({
      where: { farmerId },
      include: {
        masterController: true,
        zones: { include: { valves: { include: { slaveBoard: true } } } }
      },
      orderBy: { id: "desc" }
    });
  },

  async findById(id: bigint) {
    return prisma.field.findUnique({
      where: { id },
      include: {
        masterController: true,
        zones: { include: { valves: { include: { slaveBoard: true } } } }
      }
    });
  },

  async findFirst(where: any) {
    return prisma.field.findFirst({
      where
    });
  },

  async createField(data: any) {
    return prisma.field.create({
      data
    });
  },

  async updateField(id: bigint, data: any) {
    return prisma.field.update({
      where: { id },
      data
    });
  }
};
