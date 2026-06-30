import { Router } from "express";
import { productController } from "../controllers/productController";
import { requireAuth, requireRole } from "../middleware/auth";

export const productRoutes = Router();

productRoutes.get("/", requireAuth, requireRole("farmer", "dealer", "distributor", "sales", "admin", "tenant_admin"), productController.list);
productRoutes.post("/", requireAuth, requireRole("admin", "tenant_admin"), productController.create);
