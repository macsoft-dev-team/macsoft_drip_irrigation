import { Router } from "express";
import { zoneController } from "../controllers/zoneController";
import { requireAuth } from "../middleware/auth";

export const zoneRoutes = Router();

zoneRoutes.use(requireAuth);

zoneRoutes.get("/fields/:fieldId/zones", zoneController.listByField);
zoneRoutes.post("/fields/:fieldId/zones", zoneController.create);
zoneRoutes.get("/zones/:id", zoneController.get);
zoneRoutes.put("/zones/:id", zoneController.update);
zoneRoutes.delete("/zones/:id", zoneController.delete);
zoneRoutes.post("/zones/:id/start", zoneController.start);
zoneRoutes.post("/zones/:id/stop", zoneController.stop);
zoneRoutes.put("/zones/:id/valves", zoneController.updateValves);
