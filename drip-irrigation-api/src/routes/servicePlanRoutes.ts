import { Router } from "express";
import { servicePlanController } from "../controllers/servicePlanController";
import { requireAuth } from "../middleware/auth";

export const servicePlanRoutes = Router();

servicePlanRoutes.use(requireAuth);
servicePlanRoutes.get("/", servicePlanController.list);
servicePlanRoutes.post("/", servicePlanController.create);
