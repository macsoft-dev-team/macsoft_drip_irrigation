import { asyncHandler } from "../lib/asyncHandler.js";
import { created, ok } from "../lib/http.js";
import { parseBigIntId } from "../lib/ids.js";
import { valveService } from "../services/valveService.js";

export const valveController = {
  listByZone: asyncHandler(async (req, res) => {
    const zoneId = parseBigIntId(req.params.zoneId, "zoneId");
    return ok(res, await valveService.listByZone(req.auth, zoneId));
  }),

  listBySlaveBoard: asyncHandler(async (req, res) => {
    const slaveBoardId = parseBigIntId(req.params.slaveBoardId, "slaveBoardId");
    return ok(res, await valveService.listBySlaveBoard(req.auth, slaveBoardId));
  }),

  create: asyncHandler(async (req, res) => {
    const zoneId = parseBigIntId(req.params.zoneId, "zoneId");
    return created(res, await valveService.create(req.auth, zoneId, req.body));
  }),

  createDirect: asyncHandler(async (req, res) => {
    return created(res, await valveService.create(req.auth, null, req.body));
  }),

  update: asyncHandler(async (req, res) => {
    const valveId = parseBigIntId(req.params.valveId, "valveId");
    return ok(res, await valveService.update(req.auth, valveId, req.body));
  }),

  delete: asyncHandler(async (req, res) => {
    const valveId = parseBigIntId(req.params.valveId, "valveId");
    return ok(res, await valveService.delete(req.auth, valveId));
  }),

  assignToZone: asyncHandler(async (req, res) => {
    const valveId = parseBigIntId(req.params.valveId, "valveId");
    const zoneId = parseBigIntId(req.body.zoneId, "zoneId");
    return ok(res, await valveService.assignToZone(req.auth, valveId, zoneId));
  })
};
