import { prisma } from "../db/prisma";

export const zoneRepository = {
  async listByField(fieldId: bigint) {
    return prisma.zone.findMany({
      where: { fieldId },
      include: { valves: true },
      orderBy: { id: "asc" }
    });
  },

  async findById(id: bigint) {
    return prisma.zone.findUnique({
      where: { id },
      include: { valves: true }
    });
  },

  async findFirst(where: any) {
    return prisma.zone.findFirst({
      where
    });
  },

  async create(data: any) {
    return prisma.zone.create({
      data
    });
  },

  async update(id: bigint, data: any) {
    return prisma.zone.update({
      where: { id },
      data
    });
  },

  async delete(id: bigint) {
    return prisma.zone.update({
      where: { id },
      data: { status: "inactive" }
    });
  },

  async updateValves(zoneId: bigint, valveIds: bigint[]) {
    return prisma.$transaction(async (tx) => {
      // Unlink all current valves from this zone
      await tx.valve.updateMany({
        where: { zoneId },
        data: { zoneId: null }
      });
      // Link new valves to this zone
      if (valveIds.length > 0) {
        await tx.valve.updateMany({
          where: { id: { in: valveIds } },
          data: { zoneId }
        });
      }
      return tx.zone.findUnique({
        where: { id: zoneId },
        include: { valves: true }
      });
    });
  }
};
