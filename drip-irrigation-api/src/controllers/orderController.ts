import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { orderService } from "../services/orderService";

export const orderController = {
  list: asyncHandler(async (req, res) => ok(res, await orderService.list(req.auth))),
  create: asyncHandler(async (req, res) => created(res, await orderService.create(req.auth, req.body)))
};
