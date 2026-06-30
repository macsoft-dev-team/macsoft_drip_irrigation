import { asyncHandler } from "../lib/asyncHandler";
import { ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { adminService } from "../services/adminService";

export const adminController = {
  listFarmers: asyncHandler(async (req, res) => ok(res, await adminService.listFarmers(req.auth))),
  farmerOverview: asyncHandler(async (req, res) => ok(res, await adminService.farmerOverview(req.auth, parseBigIntId(req.params.farmerId, "farmerId")))),
  listCommands: asyncHandler(async (req, res) => ok(res, await adminService.listCommands(req.auth))),
  listActivityLogs: asyncHandler(async (req, res) => ok(res, await adminService.listActivityLogs(req.auth)))
};
