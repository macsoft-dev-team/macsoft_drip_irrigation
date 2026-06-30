import { prisma } from "../db/prisma";

export const monitoringRepository = {
  async getFieldStatus(fieldId: bigint) {
    return prisma.field.findUnique({
      where: { id: fieldId },
      include: {
        masterController: {
          include: {
            heartbeats: {
              orderBy: { id: "desc" },
              take: 1
            }
          }
        },
        zones: {
          include: {
            valves: true
          }
        }
      }
    });
  },

  async getTelemetry(masterControllerId: bigint, limit = 100) {
    return prisma.masterHeartbeat.findMany({
      where: { masterControllerId },
      orderBy: { id: "desc" },
      take: limit
    });
  },

  async getValveLogs(fieldId: bigint, limit = 100) {
    return prisma.valveStatusLog.findMany({
      where: {
        valve: {
          slaveBoard: {
            masterController: { fieldId }
          }
        }
      },
      orderBy: { id: "desc" },
      take: limit,
      include: {
        valve: true
      }
    });
  }
};
