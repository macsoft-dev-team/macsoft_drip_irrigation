import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { fieldService } from "../services/fieldService";

export const fieldController = {
  list: asyncHandler(async (req, res) => {
    return ok(res, await fieldService.listFields(req.auth));
  }),

  listByFarmer: asyncHandler(async (req, res) => {
    const farmerId = parseBigIntId(req.params.farmerId, "farmerId");
    return ok(res, await fieldService.listByFarmer(req.auth, farmerId));
  }),

  create: asyncHandler(async (req, res) => {
    const farmerId = parseBigIntId(req.params.farmerId, "farmerId");
    return created(res, await fieldService.createField(req.auth, farmerId, req.body));
  }),

  get: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.id, "id");
    return ok(res, await fieldService.getField(req.auth, fieldId));
  }),

  update: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.id, "id");
    return ok(res, await fieldService.updateField(req.auth, fieldId, req.body));
  }),

  delete: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.id, "id");
    return ok(res, await fieldService.deleteField(req.auth, fieldId));
  })
};
