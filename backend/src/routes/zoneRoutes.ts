import { Router } from "express";
import { zoneController } from "../controllers/zoneController";
import { valveController } from "../controllers/valveController";
import { requireAuth } from "../middleware/auth";

export const zoneRoutes = Router();

zoneRoutes.use(requireAuth);
zoneRoutes.patch("/:zoneId", zoneController.update);
zoneRoutes.delete("/:zoneId", zoneController.delete);

zoneRoutes.get("/:zoneId/valves", valveController.listByZone);
zoneRoutes.post("/:zoneId/valves", valveController.create);
