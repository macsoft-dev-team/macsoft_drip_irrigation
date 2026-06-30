import { Router } from "express";
import { reportController } from "../controllers/reportController";
import { requireAuth } from "../middleware/auth";

export const reportRoutes = Router();

reportRoutes.use(requireAuth);
reportRoutes.get("/", reportController.getReport);
