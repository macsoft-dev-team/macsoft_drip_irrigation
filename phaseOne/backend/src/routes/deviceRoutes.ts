import { Router } from "express";
import { deviceController } from "../controllers/deviceController";

export const deviceRoutes = Router();

deviceRoutes.post("/masters/:deviceUid/heartbeat", deviceController.heartbeat);
deviceRoutes.post("/masters/:deviceUid/ack", deviceController.ack);
