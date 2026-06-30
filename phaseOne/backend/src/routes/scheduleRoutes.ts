import { Router } from "express";
import { scheduleController } from "../controllers/scheduleController";
import { requireAuth } from "../middleware/auth";

export const scheduleRoutes = Router();

scheduleRoutes.use(requireAuth);

scheduleRoutes.get("/fields/:fieldId/schedules", scheduleController.listByField);
scheduleRoutes.post("/fields/:fieldId/schedules", scheduleController.create);
scheduleRoutes.get("/schedules/:id", scheduleController.get);
scheduleRoutes.put("/schedules/:id", scheduleController.update);
scheduleRoutes.delete("/schedules/:id", scheduleController.delete);
scheduleRoutes.patch("/schedules/:id/status", scheduleController.updateStatus);
