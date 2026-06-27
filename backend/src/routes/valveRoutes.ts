import { Router } from "express";
import { valveController } from "../controllers/valveController.js";
import { requireAuth } from "../middleware/auth.js";

export const valveRoutes = Router();

valveRoutes.use(requireAuth);

valveRoutes.post("/", valveController.createDirect);
valveRoutes.patch("/:valveId", valveController.update);
valveRoutes.delete("/:valveId", valveController.delete);
valveRoutes.patch("/:valveId/assignZone", valveController.assignToZone);

valveRoutes.get("/slaveBoards/:slaveBoardId/valves", valveController.listBySlaveBoard);
