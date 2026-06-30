import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { scheduleService } from "../services/scheduleService";

export const scheduleController = {
  listByField: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.fieldId, "fieldId");
    return ok(res, await scheduleService.listByField(req.auth, fieldId));
  }),

  create: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.fieldId, "fieldId");
    return created(res, await scheduleService.create(req.auth, fieldId, req.body));
  }),

  get: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await scheduleService.get(req.auth, id));
  }),

  update: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await scheduleService.update(req.auth, id, req.body));
  }),

  updateStatus: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await scheduleService.updateStatus(req.auth, id, req.body));
  }),

  delete: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await scheduleService.delete(req.auth, id));
  })
};
