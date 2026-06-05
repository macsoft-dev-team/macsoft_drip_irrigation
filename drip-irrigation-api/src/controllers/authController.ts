import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { authService } from "../services/authService";

export const authController = {
  registerFarmer: asyncHandler(async (req, res) => {
    const result = await authService.registerFarmer(req.body);
    return created(res, result);
  }),

  login: asyncHandler(async (req, res) => {
    const result = await authService.login(req.body);
    return ok(res, result);
  }),

  me: asyncHandler(async (req, res) => {
    const result = await authService.me(req.auth!.userId);
    return ok(res, result);
  })
};
