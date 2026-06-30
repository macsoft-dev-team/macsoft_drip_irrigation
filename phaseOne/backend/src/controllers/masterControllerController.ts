import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { masterControllerService } from "../services/masterControllerService";

export const masterControllerController = {
  createForField: asyncHandler(async (req, res) => {
    const result = await masterControllerService.createForField(req.auth, parseBigIntId(req.params.fieldId, "fieldId"), req.body);
    return created(res, result);
  }),

  getByField: asyncHandler(async (req, res) => {
    const result = await masterControllerService.getByField(req.auth, parseBigIntId(req.params.fieldId, "fieldId"));
    return ok(res, result);
  }),

  update: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    const result = await masterControllerService.update(req.auth, id, req.body);
    return ok(res, result);
  }),

  delete: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    const result = await masterControllerService.delete(req.auth, id);
    return ok(res, result);
  }),

  restart: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    const result = await masterControllerService.restart(req.auth, id);
    return ok(res, result);
  }),

  sync: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    const result = await masterControllerService.sync(req.auth, id);
    return ok(res, result);
  })
};
