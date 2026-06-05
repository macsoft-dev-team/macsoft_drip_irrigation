import { Router } from "express";
import { productController } from "../controllers/productController";
import { requireAuth } from "../middleware/auth";

export const productRoutes = Router();

productRoutes.get("/", productController.list);
productRoutes.post("/", requireAuth, productController.create);
