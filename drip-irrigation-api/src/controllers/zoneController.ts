import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { zoneService } from "../services/zoneService";

export const zoneController = {
  listByField: asyncHandler(async (req, res) => ok(res, await zoneService.listByField(req.auth, parseBigIntId(req.params.fieldId, "fieldId")))),

  create: asyncHandler(async (req, res) => created(res, await zoneService.create(req.auth, parseBigIntId(req.params.fieldId, "fieldId"), req.body))),

  update: asyncHandler(async (req, res) => ok(res, await zoneService.update(req.auth, parseBigIntId(req.params.zoneId, "zoneId"), req.body))),

  delete: asyncHandler(async (req, res) => ok(res, await zoneService.delete(req.auth, parseBigIntId(req.params.zoneId, "zoneId"))))
};
