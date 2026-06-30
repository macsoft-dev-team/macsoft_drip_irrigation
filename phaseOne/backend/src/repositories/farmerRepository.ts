import { prisma } from "../db/prisma";

export const farmerRepository = {
  async listAll(role: string, distributorId?: bigint) {
    return prisma.farmer.findMany({
      where: role === "distributor" && distributorId ? { distributorId } : {},
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

  async findById(id: bigint) {
    return prisma.farmer.findUnique({
      where: { id },
      include: {
        user: true,
        fields: {
          include: {
            masterController: true,
            zones: { include: { valves: true } }
          }
        },
        servicePlans: true,
        orders: true,
        supportTickets: true
      }
    });
  },

  async createFarmer(data: any) {
    return prisma.user.create({
      data: {
        name: data.name,
        phone: data.phone,
        email: data.email,
        passwordHash: data.passwordHash,
        role: "farmer",
        belongsToDistributorId: data.distributorId,
        belongsToDealerId: data.dealerId,
        farmer: {
          create: {
            distributorId: data.distributorId,
            dealerId: data.dealerId,
            address: data.address,
            village: data.village,
            district: data.district,
            state: data.state,
            pincode: data.pincode
          }
        }
      },
      include: { farmer: true }
    });
  },

  async updateFarmer(id: bigint, userId: bigint, profileData: any, userData: any) {
    return prisma.$transaction([
      prisma.farmer.update({
        where: { id },
        data: profileData
      }),
      prisma.user.update({
        where: { id: userId },
        data: userData
      })
    ]);
  },

  async deleteFarmer(userId: bigint) {
    return prisma.user.update({
      where: { id: userId },
      data: { status: "deleted" }
    });
  }
};
