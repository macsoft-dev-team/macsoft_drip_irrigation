import { Router } from "express";
import { masterControllerController } from "../controllers/masterControllerController";
import { requireAuth } from "../middleware/auth";

export const masterControllerRoutes = Router();

masterControllerRoutes.use(requireAuth);
masterControllerRoutes.put("/:id", masterControllerController.update);
masterControllerRoutes.delete("/:id", masterControllerController.delete);
masterControllerRoutes.post("/:id/restart", masterControllerController.restart);
masterControllerRoutes.post("/:id/sync", masterControllerController.sync);
