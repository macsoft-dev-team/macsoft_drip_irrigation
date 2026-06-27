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
    const result = await masterControllerService.update(req.auth, parseBigIntId(req.params.masterControllerId, "masterControllerId"), req.body);
    return ok(res, result);
  })
};
