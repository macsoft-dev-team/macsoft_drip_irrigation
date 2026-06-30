import { prisma } from "../db/prisma";

export const supportTicketRepository = {
  async list(where: any) {
    return prisma.supportTicket.findMany({
      where,
      orderBy: { id: "desc" },
      include: {
        farmer: { include: { user: true } },
        field: true,
        masterController: true,
        valve: true,
        assignedToUser: true
      }
    });
  },

  async findById(id: bigint) {
    return prisma.supportTicket.findUnique({
      where: { id },
      include: {
        farmer: { include: { user: true } },
        field: true,
        masterController: true,
        valve: true,
        assignedToUser: true
      }
    });
  },

  async create(data: any) {
    return prisma.supportTicket.create({
      data
    });
  },

  async update(id: bigint, data: any) {
    return prisma.supportTicket.update({
      where: { id },
      data
    });
  }
};
