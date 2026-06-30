import { Router } from "express";
import { irrigationController } from "../controllers/irrigationController";
import { requireAuth } from "../middleware/auth";

export const irrigationRoutes = Router();

irrigationRoutes.use(requireAuth);

irrigationRoutes.post("/start", irrigationController.start);
irrigationRoutes.post("/stop", irrigationController.stop);
irrigationRoutes.get("/status", irrigationController.status);
irrigationRoutes.get("/history", irrigationController.history);
