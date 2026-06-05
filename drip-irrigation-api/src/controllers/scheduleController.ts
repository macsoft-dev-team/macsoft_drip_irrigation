import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { scheduleService } from "../services/scheduleService";

export const scheduleController = {
  list: asyncHandler(async (req, res) => ok(res, await scheduleService.list(req.auth))),
  create: asyncHandler(async (req, res) => created(res, await scheduleService.create(req.auth, req.body))),
  update: asyncHandler(async (req, res) => ok(res, await scheduleService.update(req.auth, parseBigIntId(req.params.scheduleId, "scheduleId"), req.body))),
  delete: asyncHandler(async (req, res) => ok(res, await scheduleService.delete(req.auth, parseBigIntId(req.params.scheduleId, "scheduleId"))))
};
