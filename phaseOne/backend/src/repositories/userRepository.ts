import { prisma } from "../db/prisma";

export const userRepository = {
  async listAll() {
    return prisma.user.findMany({
      include: { farmer: true, distributor: true, dealer: true },
      orderBy: { id: "desc" }
    });
  },

  async listTenantUsers(distributorId: bigint | null, dealerId: bigint | null, selfId: bigint) {
    return prisma.user.findMany({
      where: {
        OR: [
          ...(distributorId ? [{ belongsToDistributorId: distributorId }, { id: selfId }] : []),
          ...(dealerId ? [{ belongsToDealerId: dealerId }, { id: selfId }] : [])
        ]
      },
      include: { farmer: true, distributor: true, dealer: true },
      orderBy: { id: "desc" }
    });
  },

  async findByPhoneOrEmail(phone: string, email?: string) {
    return prisma.user.findFirst({
      where: {
        OR: [
          { phone },
          ...(email ? [{ email }] : [])
        ]
      }
    });
  },

  async createUser(data: any) {
    return prisma.user.create({
      data,
      include: { farmer: true }
    });
  },

  async findById(id: bigint) {
    return prisma.user.findUnique({
      where: { id },
      include: { farmer: true, distributor: true, dealer: true }
    });
  },

  async updateUser(id: bigint, data: any) {
    return prisma.user.update({
      where: { id },
      data
    });
  },

  async deleteUser(id: bigint) {
    return prisma.user.update({
      where: { id },
      data: { status: "deleted" }
    });
  }
};
