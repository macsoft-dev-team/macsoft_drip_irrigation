import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { zoneService } from "../services/zoneService";

export const zoneController = {
  listByField: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.fieldId, "fieldId");
    return ok(res, await zoneService.listByField(req.auth, fieldId));
  }),

  create: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.fieldId, "fieldId");
    return created(res, await zoneService.create(req.auth, fieldId, req.body));
  }),

  get: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await zoneService.get(req.auth, id));
  }),

  update: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await zoneService.update(req.auth, id, req.body));
  }),

  delete: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await zoneService.delete(req.auth, id));
  }),

  start: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await zoneService.start(req.auth, id));
  }),

  stop: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await zoneService.stop(req.auth, id));
  }),

  updateValves: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await zoneService.updateValves(req.auth, id, req.body));
  })
};
