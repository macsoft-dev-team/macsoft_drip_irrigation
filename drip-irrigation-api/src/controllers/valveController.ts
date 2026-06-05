import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { valveService } from "../services/valveService";

export const valveController = {
  listByZone: asyncHandler(async (req, res) => ok(res, await valveService.listByZone(req.auth, parseBigIntId(req.params.zoneId, "zoneId")))),

  create: asyncHandler(async (req, res) => created(res, await valveService.create(req.auth, parseBigIntId(req.params.zoneId, "zoneId"), req.body))),

  update: asyncHandler(async (req, res) => ok(res, await valveService.update(req.auth, parseBigIntId(req.params.valveId, "valveId"), req.body))),

  delete: asyncHandler(async (req, res) => ok(res, await valveService.delete(req.auth, parseBigIntId(req.params.valveId, "valveId"))))
};
