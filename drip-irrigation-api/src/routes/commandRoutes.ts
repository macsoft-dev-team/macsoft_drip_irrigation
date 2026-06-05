import { Router } from "express";
import { commandController } from "../controllers/commandController";
import { requireAuth } from "../middleware/auth";

export const commandRoutes = Router();

commandRoutes.use(requireAuth);

commandRoutes.post("/valves/:valveId/open", commandController.openValve);
commandRoutes.post("/valves/:valveId/close", commandController.closeValve);
commandRoutes.post("/zones/:zoneId/open", commandController.openZone);
commandRoutes.post("/zones/:zoneId/close", commandController.closeZone);

commandRoutes.get("/", commandController.list);
commandRoutes.get("/:commandId", commandController.get);
