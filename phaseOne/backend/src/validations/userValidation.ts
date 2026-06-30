import { z } from "zod";

export const createUserSchema = z.object({
  name: z.string().min(2).max(150),
  phone: z.string().min(8).max(20),
  email: z.string().email().optional(),
  password: z.string().min(8),
  role: z.enum(["admin", "tenant_admin", "sales", "technician", "customer_service", "warehouse_manager", "distributor", "dealer", "farmer"]),
  hasWholesalePricing: z.boolean().default(false),
  belongsToDistributorId: z.string().optional(),
  belongsToDealerId: z.string().optional()
});

export const updateUserSchema = z.object({
  name: z.string().min(2).max(150).optional(),
  email: z.string().email().optional(),
  role: z.enum(["admin", "tenant_admin", "sales", "technician", "customer_service", "warehouse_manager", "distributor", "dealer", "farmer"]).optional(),
  status: z.enum(["active", "blocked", "deleted"]).optional(),
  hasWholesalePricing: z.boolean().optional(),
  belongsToDistributorId: z.string().optional(),
  belongsToDealerId: z.string().optional()
});

export const updateStatusSchema = z.object({
  status: z.enum(["active", "blocked", "deleted"])
});
