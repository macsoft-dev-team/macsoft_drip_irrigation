import { Router } from "express";
import { scheduleController } from "../controllers/scheduleController";
import { requireAuth } from "../middleware/auth";

export const scheduleRoutes = Router();

scheduleRoutes.use(requireAuth);
scheduleRoutes.get("/", scheduleController.list);
scheduleRoutes.post("/", scheduleController.create);
scheduleRoutes.patch("/:scheduleId", scheduleController.update);
scheduleRoutes.post("/:scheduleId/pause", scheduleController.pause);
scheduleRoutes.post("/:scheduleId/resume", scheduleController.resume);
scheduleRoutes.delete("/:scheduleId", scheduleController.delete);
