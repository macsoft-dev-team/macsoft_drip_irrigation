import { Router } from "express";
import { userController } from "../controllers/userController";
import { requireAuth } from "../middleware/auth";

export const userRoutes = Router();

userRoutes.use(requireAuth);
userRoutes.get("/", userController.list);
userRoutes.post("/", userController.create);
userRoutes.patch("/:userId", userController.update);
