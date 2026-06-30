import { Router } from "express";
import { fieldController } from "../controllers/fieldController";
import { masterControllerController } from "../controllers/masterControllerController";
import { requireAuth } from "../middleware/auth";

export const fieldRoutes = Router();

fieldRoutes.use(requireAuth);

fieldRoutes.get("/", fieldController.list);
fieldRoutes.get("/:id", fieldController.get);
fieldRoutes.put("/:id", fieldController.update);
fieldRoutes.delete("/:id", fieldController.delete);

fieldRoutes.get("/:fieldId/master", masterControllerController.getByField);
fieldRoutes.post("/:fieldId/master", masterControllerController.createForField);
