import { Router } from "express";
import { supportTicketController } from "../controllers/supportTicketController";
import { requireAuth } from "../middleware/auth";

export const supportTicketRoutes = Router();

supportTicketRoutes.use(requireAuth);
supportTicketRoutes.get("/", supportTicketController.list);
supportTicketRoutes.post("/", supportTicketController.create);
supportTicketRoutes.patch("/:ticketId", supportTicketController.update);
