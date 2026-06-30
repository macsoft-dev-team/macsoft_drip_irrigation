import { Router } from "express";
import { userController } from "../controllers/userController";
import { requireAuth } from "../middleware/auth";

export const userRoutes = Router();

userRoutes.use(requireAuth);
userRoutes.get("/", userController.list);
userRoutes.get("/:id", userController.get);
userRoutes.post("/", userController.create);
userRoutes.put("/:id", userController.update);
userRoutes.patch("/:id/status", userController.updateStatus);
userRoutes.delete("/:id", userController.delete);
