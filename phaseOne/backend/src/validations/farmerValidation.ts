import { z } from "zod";

export const createFarmerSchema = z.object({
  name: z.string().min(2).max(150),
  phone: z.string().min(8).max(20),
  email: z.string().email().optional(),
  password: z.string().min(8),
  address: z.string().optional(),
  village: z.string().optional(),
  district: z.string().optional(),
  state: z.string().optional(),
  pincode: z.string().optional(),
  distributorId: z.string().optional(),
  dealerId: z.string().optional()
});

export const updateFarmerSchema = z.object({
  name: z.string().min(2).max(150).optional(),
  email: z.string().email().optional(),
  status: z.enum(["active", "blocked", "deleted"]).optional(),
  address: z.string().optional(),
  village: z.string().optional(),
  district: z.string().optional(),
  state: z.string().optional(),
  pincode: z.string().optional(),
  distributorId: z.string().optional(),
  dealerId: z.string().optional()
});
