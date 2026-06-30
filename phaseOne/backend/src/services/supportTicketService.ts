import { createTicketSchema, updateTicketSchema } from "../validations/supportTicketValidation";
import { supportTicketRepository } from "../repositories/supportTicketRepository";
import { AppError } from "../lib/AppError";

export const supportTicketService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const where =
      auth.role === "farmer"
        ? { farmerId: auth.farmerId }
        : auth.role === "distributor"
          ? { farmer: { distributorId: auth.distributorId } }
          : auth.role === "dealer"
            ? { farmer: { dealerId: auth.dealerId } }
            : {};

    return supportTicketRepository.list(where);
  },

  async get(auth: Express.Request["auth"], id: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const ticket = await supportTicketRepository.findById(id);
    if (!ticket) throw new AppError(404, "Support ticket not found", "ticketNotFound");

    if (auth.role === "farmer" && ticket.farmerId !== auth.farmerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    } else if (auth.role === "distributor" && ticket.farmer.distributorId !== auth.distributorId) {
      throw new AppError(403, "Forbidden", "forbidden");
    } else if (auth.role === "dealer" && ticket.farmer.dealerId !== auth.dealerId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    return ticket;
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

    return supportTicketRepository.create({
      farmerId,
      fieldId: data.fieldId ? BigInt(data.fieldId) : undefined,
      masterControllerId: data.masterControllerId ? BigInt(data.masterControllerId) : undefined,
      valveId: data.valveId ? BigInt(data.valveId) : undefined,
      title: data.title,
      description: data.description,
      priority: data.priority,
      ticketType: data.ticketType
    });
  },

  async update(auth: Express.Request["auth"], ticketId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin", "technician", "customer_service"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const ticket = await supportTicketRepository.findById(ticketId);
    if (!ticket) throw new AppError(404, "Support ticket not found", "ticketNotFound");

    const data = updateTicketSchema.parse(input);

    if (auth.role === "technician") {
      const keys = Object.keys(data).filter(k => data[k as keyof typeof data] !== undefined);
      if (keys.length > 1 || !keys.includes("status")) {
        throw new AppError(403, "Technicians are only allowed to complete or update status", "forbidden");
      }
    }

    return supportTicketRepository.update(ticketId, {
      ...data,
      assignedToUserId: data.assignedToUserId ? BigInt(data.assignedToUserId) : undefined
    });
  }
};
