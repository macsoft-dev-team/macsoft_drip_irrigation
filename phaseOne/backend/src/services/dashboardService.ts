import { dashboardRepository } from "../repositories/dashboardRepository";
import { AppError } from "../lib/AppError";

export const dashboardService = {
  async getDashboard(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    return dashboardRepository.getStats(
      auth.role,
      auth.farmerId ? BigInt(auth.farmerId) : undefined,
      auth.distributorId ? BigInt(auth.distributorId) : undefined,
      auth.dealerId ? BigInt(auth.dealerId) : undefined
    );
  }
};
