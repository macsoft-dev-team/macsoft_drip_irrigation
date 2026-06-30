import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { slaveBoardService } from "../services/slaveBoardService";

export const slaveBoardController = {
  listByMaster: asyncHandler(async (req, res) => {
    const masterId = parseBigIntId(req.params.masterId, "masterId");
    const result = await slaveBoardService.listByMaster(req.auth, masterId);
    return ok(res, result);
  }),

  create: asyncHandler(async (req, res) => {
    const masterId = parseBigIntId(req.params.masterId, "masterId");
    const result = await slaveBoardService.create(req.auth, masterId, req.body);
    return created(res, result);
  }),

  get: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    const result = await slaveBoardService.get(req.auth, id);
    return ok(res, result);
  }),

  update: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    const result = await slaveBoardService.update(req.auth, id, req.body);
    return ok(res, result);
  }),

  delete: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    const result = await slaveBoardService.delete(req.auth, id);
    return ok(res, result);
  }),

  test: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    const result = await slaveBoardService.test(req.auth, id);
    return ok(res, result);
  })
};
