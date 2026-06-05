import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { productService } from "../services/productService";

export const productController = {
  list: asyncHandler(async (_req, res) => ok(res, await productService.list())),
  create: asyncHandler(async (req, res) => created(res, await productService.create(req.auth, req.body)))
};
