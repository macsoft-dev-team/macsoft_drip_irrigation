import { z } from "zod";

export const createTicketSchema = z.object({
  farmerId: z.string().optional(),
  fieldId: z.string().optional(),
  masterControllerId: z.string().optional(),
  valveId: z.string().optional(),
  title: z.string().min(1).max(200),
  description: z.string().optional(),
  priority: z.enum(["low", "medium", "high", "critical"]).default("medium"),
  ticketType: z.enum(["installation", "service"]).default("service")
});

export const updateTicketSchema = z.object({
  assignedToUserId: z.string().optional(),
  priority: z.enum(["low", "medium", "high", "critical"]).optional(),
  status: z.enum(["open", "inProgress", "resolved", "closed"]).optional(),
  title: z.string().min(1).max(200).optional(),
  description: z.string().optional()
});
