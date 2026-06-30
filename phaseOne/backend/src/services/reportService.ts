import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";

export const reportService = {
  async getReport(auth: Express.Request["auth"], type: string) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    if (type === "sales") {
      const allowed = ["admin", "tenant_admin", "sales", "distributor", "dealer"];
      if (!allowed.includes(auth.role)) {
        throw new AppError(403, "Forbidden", "forbidden");
      }

      // Query real order stats
      const distributorId = auth.distributorId;
      const dealerId = auth.dealerId;

      const orders = await prisma.order.findMany({
        where: {
          ...(distributorId ? { distributorId } : {}),
          ...(dealerId ? { dealerId } : {})
        }
      });

      const totalRevenue = orders.reduce((sum, order) => sum + Number(order.totalAmount), 0);
      const totalOrders = orders.length;

      return {
        type: "sales",
        totalRevenue,
        totalOrders,
        avgOrderValue: totalOrders > 0 ? totalRevenue / totalOrders : 0,
        orders: orders.map(o => ({
          orderNumber: o.orderNumber,
          totalAmount: o.totalAmount,
          orderStatus: o.orderStatus,
          createdAt: o.createdAt
        }))
      };
    }

    if (type === "jobs") {
      const allowed = ["admin", "tenant_admin", "technician"];
      if (!allowed.includes(auth.role)) {
        throw new AppError(403, "Forbidden", "forbidden");
      }

      // Query installation jobs (support tickets of type installation)
      const tickets = await prisma.supportTicket.findMany({
        where: {
          ticketType: "installation",
          ...(auth.role === "technician" ? { assignedToUserId: auth.userId } : {})
        }
      });

      const completed = tickets.filter(t => t.status === "resolved" || t.status === "closed").length;
      const pending = tickets.length - completed;

      return {
        type: "jobs",
        totalJobs: tickets.length,
        completedJobs: completed,
        pendingJobs: pending,
        jobs: tickets.map(t => ({
          id: t.id.toString(),
          title: t.title,
          status: t.status,
          priority: t.priority,
          createdAt: t.createdAt
        }))
      };
    }

    if (type === "service") {
      const allowed = ["admin", "tenant_admin", "customer_service"];
      if (!allowed.includes(auth.role)) {
        throw new AppError(403, "Forbidden", "forbidden");
      }

      // Query service tickets
      const tickets = await prisma.supportTicket.findMany({
        where: { ticketType: "service" }
      });

      const openCount = tickets.filter(t => t.status === "open").length;
      const inProgressCount = tickets.filter(t => t.status === "inProgress").length;
      const resolvedCount = tickets.filter(t => t.status === "resolved").length;

      return {
        type: "service",
        totalTickets: tickets.length,
        openTickets: openCount,
        inProgressTickets: inProgressCount,
        resolvedTickets: resolvedCount,
        tickets: tickets.map(t => ({
          id: t.id.toString(),
          title: t.title,
          status: t.status,
          priority: t.priority,
          createdAt: t.createdAt
        }))
      };
    }

    if (type === "own") {
      if (auth.role !== "farmer") {
        throw new AppError(403, "Forbidden", "forbidden");
      }

      const farmerId = auth.farmerId!;

      // Query farmer commands and schedules
      const commandCount = await prisma.command.count({
        where: { farmerId }
      });

      const scheduleCount = await prisma.irrigationSchedule.count({
        where: { farmerId }
      });

      return {
        type: "own",
        farmerId: farmerId.toString(),
        totalCommandsRun: commandCount,
        activeIrrigationSchedules: scheduleCount,
        message: "Farmer usage statistics retrieved successfully"
      };
    }

    throw new AppError(400, "Invalid report type requested", "invalidReportType");
  }
};
