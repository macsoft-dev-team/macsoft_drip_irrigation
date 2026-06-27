import { Router } from "express";
import { fieldController } from "../controllers/fieldController";
import { masterControllerController } from "../controllers/masterControllerController";
import { zoneController } from "../controllers/zoneController";
import { requireAuth } from "../middleware/auth";

export const fieldRoutes = Router();

fieldRoutes.use(requireAuth);

fieldRoutes.get("/", fieldController.list);
fieldRoutes.post("/", fieldController.create);
fieldRoutes.get("/:fieldId", fieldController.get);
fieldRoutes.patch("/:fieldId", fieldController.update);
fieldRoutes.delete("/:fieldId", fieldController.delete);

fieldRoutes.post("/:fieldId/masterController", masterControllerController.createForField);
fieldRoutes.get("/:fieldId/masterController", masterControllerController.getByField);

fieldRoutes.get("/:fieldId/zones", zoneController.listByField);
fieldRoutes.post("/:fieldId/zones", zoneController.create);
