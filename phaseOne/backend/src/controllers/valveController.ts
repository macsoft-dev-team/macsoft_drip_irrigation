import { asyncHandler } from "../lib/asyncHandler";
import { created, ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { valveService } from "../services/valveService";

export const valveController = {
  listBySlaveBoard: asyncHandler(async (req, res) => {
    const slaveId = parseBigIntId(req.params.slaveId, "slaveId");
    return ok(res, await valveService.listBySlaveBoard(req.auth, slaveId));
  }),

  create: asyncHandler(async (req, res) => {
    const slaveId = parseBigIntId(req.params.slaveId, "slaveId");
    return created(res, await valveService.create(req.auth, slaveId, req.body));
  }),

  get: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await valveService.get(req.auth, id));
  }),

  update: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await valveService.update(req.auth, id, req.body));
  }),

  delete: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await valveService.delete(req.auth, id));
  }),

  open: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await valveService.open(req.auth, id));
  }),

  close: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await valveService.close(req.auth, id));
  }),

  test: asyncHandler(async (req, res) => {
    const id = parseBigIntId(req.params.id, "id");
    return ok(res, await valveService.test(req.auth, id));
  })
};
