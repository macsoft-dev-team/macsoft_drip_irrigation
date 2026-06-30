import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { supportTicketService } from "../services/supportTicketService";

export const supportTicketController = {
  list: asyncHandler(async (req, res) => {
    return ok(res, await supportTicketService.list(req.auth));
  }),

  create: asyncHandler(async (req, res) => {
    return created(res, await supportTicketService.create(req.auth, req.body));
  }),

  get: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await supportTicketService.get(req.auth, id));
  }),

  update: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await supportTicketService.update(req.auth, id, req.body));
  })
};
