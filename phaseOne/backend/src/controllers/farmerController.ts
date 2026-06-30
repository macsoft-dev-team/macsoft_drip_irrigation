import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { farmerService } from "../services/farmerService";

export const farmerController = {
  list: asyncHandler(async (req, res) => {
    const result = await farmerService.list(req.auth);
    return ok(res, result);
  }),

  get: asyncHandler(async (req, res) => {
    const farmerId = parseBigIntId(req.params.id, "id");
    const result = await farmerService.get(req.auth, farmerId);
    return ok(res, result);
  }),

  create: asyncHandler(async (req, res) => {
    const result = await farmerService.create(req.auth, req.body);
    return created(res, result);
  }),

  update: asyncHandler(async (req, res) => {
    const farmerId = parseBigIntId(req.params.id, "id");
    const result = await farmerService.update(req.auth, farmerId, req.body);
    return ok(res, result);
  }),

  delete: asyncHandler(async (req, res) => {
    const farmerId = parseBigIntId(req.params.id, "id");
    const result = await farmerService.delete(req.auth, farmerId);
    return ok(res, result);
  })
};
