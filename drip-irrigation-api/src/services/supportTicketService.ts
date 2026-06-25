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
  priority: z.enum(["low", "medium", "high", "critical"]).default("medium"),
  ticketType: z.enum(["installation", "service"]).default("service")
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
      where:
        auth.role === "farmer"
          ? { farmerId: auth.farmerId }
          : auth.role === "distributor"
            ? { farmer: { distributorId: auth.distributorId } }
            : auth.role === "dealer"
              ? { farmer: { dealerId: auth.dealerId } }
              : {}, // others view all
      orderBy: { id: "desc" }
    });
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const data = createTicketSchema.parse(input);

    if (data.ticketType === "installation") {
      const allowed = ["farmer", "dealer", "distributor", "customer_service", "sales", "admin", "tenant_admin"];
      if (!allowed.includes(auth.role)) {
        throw new AppError(403, "Forbidden", "forbidden");
      }
    } else {
      const allowed = ["farmer", "dealer", "distributor", "customer_service", "admin", "tenant_admin"];
      if (!allowed.includes(auth.role)) {
        throw new AppError(403, "Forbidden", "forbidden");
      }
    }

    const farmerId = auth.role === "farmer" ? auth.farmerId! : BigInt(data.farmerId!);

    return prisma.supportTicket.create({
      data: {
        farmerId,
        fieldId: data.fieldId ? BigInt(data.fieldId) : undefined,
        masterControllerId: data.masterControllerId ? BigInt(data.masterControllerId) : undefined,
        valveId: data.valveId ? BigInt(data.valveId) : undefined,
        title: data.title,
        description: data.description,
        priority: data.priority,
        ticketType: data.ticketType
      }
    });
  },

  async update(auth: Express.Request["auth"], ticketId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin", "technician", "customer_service"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const ticket = await prisma.supportTicket.findUnique({
      where: { id: ticketId }
    });
    if (!ticket) throw new AppError(404, "Support ticket not found", "ticketNotFound");

    const data = updateTicketSchema.parse(input);

    // Technician can only change status (completing installation/service)
    if (auth.role === "technician") {
      const keys = Object.keys(data).filter(k => data[k as keyof typeof data] !== undefined);
      if (keys.length > 1 || !keys.includes("status")) {
        throw new AppError(403, "Technicians are only allowed to complete or update status", "forbidden");
      }
    }

    return prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        ...data,
        assignedToUserId: data.assignedToUserId ? BigInt(data.assignedToUserId) : undefined
      }
    });
  }
};
