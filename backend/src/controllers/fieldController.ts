import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { fieldService } from "../services/fieldService";

export const fieldController = {
  list: asyncHandler(async (req, res) => ok(res, await fieldService.listFields(req.auth))),

  create: asyncHandler(async (req, res) => {
    return created(res, await fieldService.createField(req.auth, req.body));
  }),

  get: asyncHandler(async (req, res) => ok(res, await fieldService.getField(req.auth, parseBigIntId(req.params.fieldId, "fieldId")))),

  update: asyncHandler(async (req, res) => ok(res, await fieldService.updateField(req.auth, parseBigIntId(req.params.fieldId, "fieldId"), req.body))),

  delete: asyncHandler(async (req, res) => ok(res, await fieldService.deleteField(req.auth, parseBigIntId(req.params.fieldId, "fieldId"))))
};
