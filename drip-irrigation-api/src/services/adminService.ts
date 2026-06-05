import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";

export const adminService = {
  async listFarmers(auth: Express.Request["auth"]) {
    if (!auth || !["admin", "distributor", "technician"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    return prisma.farmer.findMany({
      where: auth.role === "distributor" ? { distributorId: auth.distributorId } : {},
      include: {
        user: true,
        fields: {
          include: {
            masterController: true,
            zones: { include: { valves: true } }
          }
        }
      },
      orderBy: { id: "desc" }
    });
  },

  async farmerOverview(auth: Express.Request["auth"], farmerId: bigint) {
    if (!auth || !["admin", "distributor", "technician"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const farmer = await prisma.farmer.findUnique({
      where: { id: farmerId },
      include: {
        user: true,
        fields: {
          include: {
            masterController: true,
            zones: {
              include: { valves: true }
            }
          }
        },
        servicePlans: true,
        orders: true,
        supportTickets: true
      }
    });

    if (!farmer) throw new AppError(404, "Farmer not found", "farmerNotFound");

    if (auth.role === "distributor" && farmer.distributorId !== auth.distributorId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    return farmer;
  },

  async listCommands(auth: Express.Request["auth"]) {
    if (!auth || !["admin", "technician", "distributor"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    return prisma.command.findMany({
      include: {
        farmer: { include: { user: true } },
        field: true,
        masterController: true,
        items: { include: { valve: true } }
      },
      orderBy: { id: "desc" },
      take: 200
    });
  }
};
