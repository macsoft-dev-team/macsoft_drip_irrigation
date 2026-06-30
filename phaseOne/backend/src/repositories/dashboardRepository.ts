import { prisma } from "../db/prisma";

export const dashboardRepository = {
  async getStats(role: string, farmerId?: bigint, distributorId?: bigint, dealerId?: bigint) {
    // Construct base where filters depending on role
    const userWhere: any = {};
    const farmerWhere: any = {};
    const fieldWhere: any = {};
    const mcWhere: any = {};
    const valveWhere: any = {};
    const ticketWhere: any = {};

    if (role === "farmer" && farmerId) {
      userWhere.role = "farmer";
      userWhere.id = farmerId;
      farmerWhere.id = farmerId;
      fieldWhere.farmerId = farmerId;
      mcWhere.field = { farmerId };
      valveWhere.slaveBoard = { masterController: { field: { farmerId } } };
      ticketWhere.farmerId = farmerId;
    } else if (role === "distributor" && distributorId) {
      userWhere.belongsToDistributorId = distributorId;
      farmerWhere.distributorId = distributorId;
      fieldWhere.farmer = { distributorId };
      mcWhere.field = { farmer: { distributorId } };
      valveWhere.slaveBoard = { masterController: { field: { farmer: { distributorId } } } };
      ticketWhere.farmer = { distributorId };
    } else if (role === "dealer" && dealerId) {
      userWhere.belongsToDealerId = dealerId;
      farmerWhere.dealerId = dealerId;
      fieldWhere.farmer = { dealerId };
      mcWhere.field = { farmer: { dealerId } };
      valveWhere.slaveBoard = { masterController: { field: { farmer: { dealerId } } } };
      ticketWhere.farmer = { dealerId };
    }

    const [
      totalUsers,
      totalFarmers,
      totalFields,
      onlineControllers,
      offlineControllers,
      unresolvedTickets,
      activeValves,
      openValves
    ] = await prisma.$transaction([
      prisma.user.count({ where: userWhere }),
      prisma.farmer.count({ where: farmerWhere }),
      prisma.field.count({ where: fieldWhere }),
      prisma.masterController.count({ where: { ...mcWhere, status: "online" } }),
      prisma.masterController.count({ where: { ...mcWhere, status: "offline" } }),
      prisma.supportTicket.count({ where: { ...ticketWhere, status: { in: ["open", "inProgress"] } } }),
      prisma.valve.count({ where: valveWhere }),
      prisma.valve.count({ where: { ...valveWhere, status: "open" } })
    ]);

    return {
      usersCount: totalUsers,
      farmersCount: totalFarmers,
      fieldsCount: totalFields,
      controllers: {
        online: onlineControllers,
        offline: offlineControllers,
        total: onlineControllers + offlineControllers
      },
      tickets: {
        unresolved: unresolvedTickets
      },
      valves: {
        active: activeValves,
        open: openValves
      }
    };
  }
};
