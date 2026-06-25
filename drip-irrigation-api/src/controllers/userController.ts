import { asyncHandler } from "../lib/asyncHandler";
import { ok, created } from "../lib/http";
import { userService } from "../services/userService";

export const userController = {
  list: asyncHandler(async (req, res) => {
    const result = await userService.list(req.auth);
    return ok(res, result);
  }),

  create: asyncHandler(async (req, res) => {
    const result = await userService.create(req.auth, req.body);
    return created(res, result);
  }),

  update: asyncHandler(async (req, res) => {
    const userId = BigInt(req.params.userId as string);
    const result = await userService.update(req.auth, userId, req.body);
    return ok(res, result);
  })
};
