import { Router } from "express";
import { slaveBoardController } from "../controllers/slaveBoardController";
import { requireAuth } from "../middleware/auth";

export const slaveBoardRoutes = Router();

slaveBoardRoutes.use(requireAuth);

slaveBoardRoutes.get("/masters/:masterId/slaves", slaveBoardController.listByMaster);
slaveBoardRoutes.post("/masters/:masterId/slaves", slaveBoardController.create);
slaveBoardRoutes.get("/slaves/:id", slaveBoardController.get);
slaveBoardRoutes.put("/slaves/:id", slaveBoardController.update);
slaveBoardRoutes.delete("/slaves/:id", slaveBoardController.delete);
slaveBoardRoutes.post("/slaves/:id/test", slaveBoardController.test);
