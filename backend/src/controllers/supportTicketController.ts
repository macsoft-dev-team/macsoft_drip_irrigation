import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { supportTicketService } from "../services/supportTicketService";

export const supportTicketController = {
  list: asyncHandler(async (req, res) => ok(res, await supportTicketService.list(req.auth))),
  create: asyncHandler(async (req, res) => created(res, await supportTicketService.create(req.auth, req.body))),
  update: asyncHandler(async (req, res) => ok(res, await supportTicketService.update(req.auth, parseBigIntId(req.params.ticketId, "ticketId"), req.body)))
};
