import { Router } from "express";
import { orderController } from "../controllers/orderController";
import { requireAuth } from "../middleware/auth";

export const orderRoutes = Router();

orderRoutes.use(requireAuth);
orderRoutes.get("/", orderController.list);
orderRoutes.post("/", orderController.create);
