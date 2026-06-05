import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";

const createTicketSchema = z.object({
  farmerId: z.string().optional(),
  fieldId: z.string().optional(),
  masterControllerId: z.string().optional(),
  valveId: z.string().optional(),
  title: z.string().min(1).max(200),
  description: z.string().optional(),
  priority: z.enum(["low", "medium", "high", "critical"]).default("medium")
});

const updateTicketSchema = z.object({
  assignedToUserId: z.string().optional(),
  priority: z.enum(["low", "medium", "high", "critical"]).optional(),
  status: z.enum(["open", "inProgress", "resolved", "closed"]).optional(),
  title: z.string().min(1).max(200).optional(),
  description: z.string().optional()
});

export const supportTicketService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    return prisma.supportTicket.findMany({
      where: auth.role === "farmer" ? { farmerId: auth.farmerId } : {},
      orderBy: { id: "desc" }
    });
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const data = createTicketSchema.parse(input);

    const farmerId = auth.role === "farmer" ? auth.farmerId! : BigInt(data.farmerId!);

    return prisma.supportTicket.create({
      data: {
        farmerId,
        fieldId: data.fieldId ? BigInt(data.fieldId) : undefined,
        masterControllerId: data.masterControllerId ? BigInt(data.masterControllerId) : undefined,
        valveId: data.valveId ? BigInt(data.valveId) : undefined,
        title: data.title,
        description: data.description,
        priority: data.priority
      }
    });
  },

  async update(auth: Express.Request["auth"], ticketId: bigint, input: unknown) {
    if (!auth || !["admin", "technician", "distributor"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateTicketSchema.parse(input);

    return prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        ...data,
        assignedToUserId: data.assignedToUserId ? BigInt(data.assignedToUserId) : undefined
      }
    });
  }
};
