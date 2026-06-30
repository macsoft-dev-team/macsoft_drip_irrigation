import { prisma } from "../db/prisma";

export const activityLogService = {
  async log(
    userId: bigint,
    action: "create" | "update" | "delete" | "trigger",
    entityType: "field" | "zone" | "valve" | "schedule" | "command",
    entityId: bigint,
    details?: any
  ) {
    try {
      await prisma.activityLog.create({
        data: {
          userId,
          action,
          entityType,
          entityId,
          details: details ? JSON.stringify(details) : null
        }
      });
      console.log(`[ACTIVITY LOG] Logged action: ${action} on ${entityType} ID ${entityId.toString()} by User ID ${userId.toString()}`);
    } catch (error) {
      console.error("[ACTIVITY LOG] Failed to write log:", error);
    }
  }
};
