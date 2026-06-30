import { asyncHandler } from "../lib/asyncHandler";
import { ok } from "../lib/http";
import { parseBigIntId } from "../lib/ids";
import { monitoringService } from "../services/monitoringService";

export const monitoringController = {
  status: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.fieldId, "fieldId");
    return ok(res, await monitoringService.getFieldStatus(req.auth, fieldId));
  }),

  telemetry: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.fieldId, "fieldId");
    return ok(res, await monitoringService.getTelemetry(req.auth, fieldId));
  }),

  logs: asyncHandler(async (req, res) => {
    const fieldId = parseBigIntId(req.params.fieldId, "fieldId");
    return ok(res, await monitoringService.getLogs(req.auth, fieldId));
  })
};
