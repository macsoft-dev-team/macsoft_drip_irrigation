import { Router } from "express";
import { monitoringController } from "../controllers/monitoringController";
import { requireAuth } from "../middleware/auth";

export const monitoringRoutes = Router();

monitoringRoutes.use(requireAuth);

monitoringRoutes.get("/fields/:fieldId/status", monitoringController.status);
monitoringRoutes.get("/fields/:fieldId/telemetry", monitoringController.telemetry);
monitoringRoutes.get("/fields/:fieldId/logs", monitoringController.logs);
