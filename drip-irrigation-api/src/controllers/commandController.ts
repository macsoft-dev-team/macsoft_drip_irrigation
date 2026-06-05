import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { commandService } from "../services/commandService";

export const commandController = {
  openValve: asyncHandler(async (req, res) => {
    const command = await commandService.createValveCommand(req.auth, parseBigIntId(req.params.valveId, "valveId"), "open");
    return created(res, command);
  }),

  closeValve: asyncHandler(async (req, res) => {
    const command = await commandService.createValveCommand(req.auth, parseBigIntId(req.params.valveId, "valveId"), "close");
    return created(res, command);
  }),

  openZone: asyncHandler(async (req, res) => {
    const command = await commandService.createZoneCommand(req.auth, parseBigIntId(req.params.zoneId, "zoneId"), "open");
    return created(res, command);
  }),

  closeZone: asyncHandler(async (req, res) => {
    const command = await commandService.createZoneCommand(req.auth, parseBigIntId(req.params.zoneId, "zoneId"), "close");
    return created(res, command);
  }),

  list: asyncHandler(async (req, res) => {
    const commands = await commandService.list(req.auth, { status: req.query.status?.toString() });
    return ok(res, commands);
  }),

  get: asyncHandler(async (req, res) => {
    const command = await commandService.get(req.auth, parseBigIntId(req.params.commandId, "commandId"));
    return ok(res, command);
  })
};
