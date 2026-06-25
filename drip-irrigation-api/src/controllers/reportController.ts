import { asyncHandler } from "../lib/asyncHandler";
import { ok } from "../lib/http";
import { reportService } from "../services/reportService";

export const reportController = {
  getReport: asyncHandler(async (req, res) => {
    const reportType = req.query.type as string || "sales";
    const result = await reportService.getReport(req.auth, reportType);
    return ok(res, result);
  })
};
