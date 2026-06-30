import { prisma } from "../db/prisma";

export const scheduleRepository = {
  async listAll(farmerId?: bigint) {
    return prisma.irrigationSchedule.findMany({
      where: farmerId ? { farmerId } : {},
      orderBy: { id: "desc" }
    });
  },

  async listByField(fieldId: bigint) {
    return prisma.irrigationSchedule.findMany({
      where: { fieldId },
      orderBy: { id: "desc" }
    });
  },

  async findById(id: bigint) {
    return prisma.irrigationSchedule.findUnique({
      where: { id }
    });
  },

  async create(data: any) {
    return prisma.irrigationSchedule.create({
      data
    });
  },

  async update(id: bigint, data: any) {
    return prisma.irrigationSchedule.update({
      where: { id },
      data
    });
  },

  async delete(id: bigint) {
    return prisma.irrigationSchedule.update({
      where: { id },
      data: { status: "deleted" }
    });
  }
};
