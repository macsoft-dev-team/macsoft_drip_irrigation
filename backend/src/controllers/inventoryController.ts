import { asyncHandler } from "../lib/asyncHandler";
import { ok, created } from "../lib/http";
import { inventoryService } from "../services/inventoryService";

export const inventoryController = {
  list: asyncHandler(async (req, res) => {
    const result = await inventoryService.list(req.auth);
    return ok(res, result);
  }),

  upsert: asyncHandler(async (req, res) => {
    const result = await inventoryService.upsert(req.auth, req.body);
    return created(res, result);
  })
};
