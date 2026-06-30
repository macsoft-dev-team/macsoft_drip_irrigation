import { asyncHandler } from "../lib/asyncHandler";
import { ok, created } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { userService } from "../services/userService";

export const userController = {
  list: asyncHandler(async (req, res) => {
    const result = await userService.list(req.auth);
    return ok(res, result);
  }),

  get: asyncHandler(async (req, res) => {
    const userId = parseBigIntId(req.params.id, "id");
    const result = await userService.get(req.auth, userId);
    return ok(res, result);
  }),

  create: asyncHandler(async (req, res) => {
    const result = await userService.create(req.auth, req.body);
    return created(res, result);
  }),

  update: asyncHandler(async (req, res) => {
    const userId = parseBigIntId(req.params.id, "id");
    const result = await userService.update(req.auth, userId, req.body);
    return ok(res, result);
  }),

  updateStatus: asyncHandler(async (req, res) => {
    const userId = parseBigIntId(req.params.id, "id");
    const result = await userService.updateStatus(req.auth, userId, req.body);
    return ok(res, result);
  }),

  delete: asyncHandler(async (req, res) => {
    const userId = parseBigIntId(req.params.id, "id");
    const result = await userService.delete(req.auth, userId);
    return ok(res, result);
  })
};
