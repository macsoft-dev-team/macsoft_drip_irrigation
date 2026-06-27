import { Router } from "express";
import { inventoryController } from "../controllers/inventoryController";
import { requireAuth } from "../middleware/auth";

export const inventoryRoutes = Router();

inventoryRoutes.use(requireAuth);
inventoryRoutes.get("/", inventoryController.list);
inventoryRoutes.post("/", inventoryController.upsert);
