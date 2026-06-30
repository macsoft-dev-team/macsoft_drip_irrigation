import { asyncHandler } from "../lib/asyncHandler";
import { ok } from "../lib/http";
import { irrigationService } from "../services/irrigationService";

export const irrigationController = {
  start: asyncHandler(async (req, res) => {
    return ok(res, await irrigationService.start(req.auth, req.body));
  }),

  stop: asyncHandler(async (req, res) => {
    return ok(res, await irrigationService.stop(req.auth, req.body));
  }),

  status: asyncHandler(async (req, res) => {
    return ok(res, await irrigationService.getStatus(req.auth));
  }),

  history: asyncHandler(async (req, res) => {
    return ok(res, await irrigationService.getHistory(req.auth));
  })
};
