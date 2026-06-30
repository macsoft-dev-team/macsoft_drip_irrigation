import { Router } from "express";
import { adminController } from "../controllers/adminController";
import { requireAuth, requireRole } from "../middleware/auth";

export const adminRoutes = Router();

adminRoutes.use(requireAuth);
adminRoutes.use(requireRole("admin", "technician", "distributor"));

adminRoutes.get("/farmers", adminController.listFarmers);
adminRoutes.get("/farmers/:farmerId/overview", adminController.farmerOverview);
adminRoutes.get("/commands", adminController.listCommands);
adminRoutes.get("/activity-logs", adminController.listActivityLogs);
