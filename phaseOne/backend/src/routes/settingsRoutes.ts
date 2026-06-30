import { Router } from "express";
import { requireAuth, requireRole } from "../middleware/auth";
import { ok } from "../lib/http";
import { asyncHandler } from "../lib/asyncHandler";
import { AppError } from "../lib/AppError";

export const settingsRoutes = Router();

settingsRoutes.use(requireAuth);

// Tenant Settings: Platform Admin & Tenant Admin
settingsRoutes.get("/tenant", requireRole("admin", "tenant_admin"), asyncHandler(async (req, res) => {
  return ok(res, {
    tenantId: req.auth?.distributorId?.toString() || req.auth?.dealerId?.toString() || "central",
    settings: {
      alertNotificationEmail: "alerts@irrigation.com",
      autoDispatchEnabled: true,
      defaultTaxRatePercentage: 18.0
    }
  });
}));

settingsRoutes.patch("/tenant", requireRole("admin", "tenant_admin"), asyncHandler(async (req, res) => {
  return ok(res, {
    message: "Tenant settings updated successfully",
    settings: req.body
  });
}));

// Platform Settings: Platform Admin Only
settingsRoutes.get("/platform", requireRole("admin"), asyncHandler(async (req, res) => {
  // If the admin actually belongs to a distributor or dealer, they are a tenant admin in that scope, not platform admin.
  if (req.auth?.distributorId || req.auth?.dealerId) {
    throw new AppError(403, "Forbidden", "forbidden");
  }

  return ok(res, {
    platform: {
      maintenanceMode: false,
      enableNewSignups: true,
      maxTenantsLimit: 100,
      supportedGatewayVersions: ["v1", "v2"]
    }
  });
}));

settingsRoutes.patch("/platform", requireRole("admin"), asyncHandler(async (req, res) => {
  if (req.auth?.distributorId || req.auth?.dealerId) {
    throw new AppError(403, "Forbidden", "forbidden");
  }

  return ok(res, {
    message: "Platform settings updated successfully",
    platform: req.body
  });
}));
