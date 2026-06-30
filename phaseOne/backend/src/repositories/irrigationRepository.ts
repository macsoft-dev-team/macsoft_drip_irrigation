import { prisma } from "../db/prisma";

export const irrigationRepository = {
  async getLatestCommandForActuator(targetType: "valve" | "zone" | "field" | "motor", targetId: bigint) {
    return prisma.command.findFirst({
      where: { targetType, targetId },
      orderBy: { id: "desc" }
    });
  },

  async listRecentCommands(limit = 50) {
    return prisma.command.findMany({
      orderBy: { id: "desc" },
      take: limit,
      include: {
        masterController: { include: { field: true } }
      }
    });
  },

  async listCommandsByField(fieldId: bigint, limit = 50) {
    return prisma.command.findMany({
      where: {
        masterController: { fieldId }
      },
      orderBy: { id: "desc" },
      take: limit
    });
  }
};
