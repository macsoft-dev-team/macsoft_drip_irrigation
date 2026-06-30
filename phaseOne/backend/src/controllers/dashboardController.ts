import { asyncHandler } from "../lib/asyncHandler";
import { ok } from "../lib/http";
import { dashboardService } from "../services/dashboardService";

export const dashboardController = {
  getStats: asyncHandler(async (req, res) => {
    return ok(res, await dashboardService.getDashboard(req.auth));
  })
};
