import { Router } from "express";
import { valveController } from "../controllers/valveController";
import { requireAuth } from "../middleware/auth";

export const valveRoutes = Router();

valveRoutes.use(requireAuth);

valveRoutes.get("/slaves/:slaveId/valves", valveController.listBySlaveBoard);
valveRoutes.post("/slaves/:slaveId/valves", valveController.create);
valveRoutes.get("/valves/:id", valveController.get);
valveRoutes.put("/valves/:id", valveController.update);
valveRoutes.delete("/valves/:id", valveController.delete);
valveRoutes.post("/valves/:id/open", valveController.open);
valveRoutes.post("/valves/:id/close", valveController.close);
valveRoutes.post("/valves/:id/test", valveController.test);
