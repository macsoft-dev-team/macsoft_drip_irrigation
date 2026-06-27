import { Router } from "express";
import { slaveBoardController } from "../controllers/slaveBoardController.js";
import { requireAuth } from "../middleware/auth.js";

export const slaveBoardRoutes = Router();

slaveBoardRoutes.use(requireAuth);

slaveBoardRoutes.get("/masterControllers/:masterControllerId/slaveBoards", slaveBoardController.listByMasterController);
slaveBoardRoutes.post("/masterControllers/:masterControllerId/slaveBoards", slaveBoardController.create);
slaveBoardRoutes.patch("/slaveBoards/:slaveBoardId", slaveBoardController.update);
slaveBoardRoutes.delete("/slaveBoards/:slaveBoardId", slaveBoardController.delete);
