import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { productService } from "../services/productService";

export const productController = {
  list: asyncHandler(async (req, res) => ok(res, await productService.list(req.auth))),
  create: asyncHandler(async (req, res) => created(res, await productService.create(req.auth, req.body)))
};
