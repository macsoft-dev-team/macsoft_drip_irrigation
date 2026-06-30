import { Router } from "express";
import { farmerController } from "../controllers/farmerController";
import { fieldController } from "../controllers/fieldController";
import { requireAuth } from "../middleware/auth";

export const farmerRoutes = Router();

farmerRoutes.use(requireAuth);

farmerRoutes.get("/", farmerController.list);
farmerRoutes.get("/:id", farmerController.get);
farmerRoutes.post("/", farmerController.create);
farmerRoutes.put("/:id", farmerController.update);
farmerRoutes.delete("/:id", farmerController.delete);

farmerRoutes.get("/:farmerId/fields", fieldController.listByFarmer);
farmerRoutes.post("/:farmerId/fields", fieldController.create);
