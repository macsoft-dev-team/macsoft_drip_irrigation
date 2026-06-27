import { Router } from "express";
import { valveController } from "../controllers/valveController";
import { requireAuth } from "../middleware/auth";

export const valveRoutes = Router();

valveRoutes.use(requireAuth);
valveRoutes.patch("/:valveId", valveController.update);
valveRoutes.delete("/:valveId", valveController.delete);
