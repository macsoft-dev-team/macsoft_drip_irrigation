import { Router } from "express";
import { masterControllerController } from "../controllers/masterControllerController";
import { requireAuth } from "../middleware/auth";

export const masterControllerRoutes = Router();

masterControllerRoutes.use(requireAuth);
masterControllerRoutes.patch("/:masterControllerId", masterControllerController.update);
