import { asyncHandler } from "../lib/asyncHandler.js";
import { created, ok } from "../lib/http.js";
import { parseBigIntId } from "../lib/ids.js";
import { slaveBoardService } from "../services/slaveBoardService.js";

export const slaveBoardController = {
  listByMasterController: asyncHandler(async (req, res) => {
    const masterControllerId = parseBigIntId(req.params.masterControllerId, "masterControllerId");
    const result = await slaveBoardService.listByMasterController(req.auth, masterControllerId);
    return ok(res, result);
  }),

  create: asyncHandler(async (req, res) => {
    const masterControllerId = parseBigIntId(req.params.masterControllerId, "masterControllerId");
    const result = await slaveBoardService.create(req.auth, masterControllerId, req.body);
    return created(res, result);
  }),

  update: asyncHandler(async (req, res) => {
    const slaveBoardId = parseBigIntId(req.params.slaveBoardId, "slaveBoardId");
    const result = await slaveBoardService.update(req.auth, slaveBoardId, req.body);
    return ok(res, result);
  }),

  delete: asyncHandler(async (req, res) => {
    const slaveBoardId = parseBigIntId(req.params.slaveBoardId, "slaveBoardId");
    const result = await slaveBoardService.delete(req.auth, slaveBoardId);
    return ok(res, result);
  })
};
