import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { servicePlanService } from "../services/servicePlanService";

export const servicePlanController = {
  list: asyncHandler(async (req, res) => ok(res, await servicePlanService.list(req.auth))),
  create: asyncHandler(async (req, res) => created(res, await servicePlanService.create(req.auth, req.body)))
};
