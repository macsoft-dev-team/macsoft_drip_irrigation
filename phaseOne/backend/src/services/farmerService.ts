import { createFarmerSchema, updateFarmerSchema } from "../validations/farmerValidation";
import { farmerRepository } from "../repositories/farmerRepository";
import { AppError } from "../lib/AppError";
import { hashPassword } from "../lib/password";
import { activityLogService } from "./activityLogService";

export const farmerService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (!["admin", "distributor", "technician"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const distId = auth.role === "distributor" ? auth.distributorId : undefined;
    return farmerRepository.listAll(auth.role, distId);
  },

  async get(auth: Express.Request["auth"], farmerId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (!["admin", "distributor", "technician"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const farmer = await farmerRepository.findById(farmerId);
    if (!farmer) throw new AppError(404, "Farmer profile not found", "farmerNotFound");

    if (auth.role === "distributor" && farmer.distributorId !== auth.distributorId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    return farmer;
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (!["admin", "distributor"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = createFarmerSchema.parse(input);
    const passwordHash = await hashPassword(data.password);

    const distributorId = auth.role === "distributor" ? auth.distributorId : (data.distributorId ? BigInt(data.distributorId) : null);
    const dealerId = data.dealerId ? BigInt(data.dealerId) : null;

    const result = await farmerRepository.createFarmer({
      name: data.name,
      phone: data.phone,
      email: data.email,
      passwordHash,
      distributorId,
      dealerId,
      address: data.address,
      village: data.village,
      district: data.district,
      state: data.state,
      pincode: data.pincode
    });

    if (result && result.farmer) {
      await activityLogService.log(auth.userId, "create", "farmer" as any, result.farmer.id, { name: data.name });
    }

    return result;
  },

  async update(auth: Express.Request["auth"], farmerId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (!["admin", "distributor"].includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const farmer = await farmerRepository.findById(farmerId);
    if (!farmer) throw new AppError(404, "Farmer profile not found", "farmerNotFound");

    if (auth.role === "distributor" && farmer.distributorId !== auth.distributorId) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateFarmerSchema.parse(input);

    const profileData = {
      address: data.address,
      village: data.village,
      district: data.district,
      state: data.state,
      pincode: data.pincode,
      distributorId: data.distributorId ? BigInt(data.distributorId) : undefined,
      dealerId: data.dealerId ? BigInt(data.dealerId) : undefined
    };

    const userData = {
      name: data.name,
      email: data.email,
      status: data.status,
      belongsToDistributorId: data.distributorId ? BigInt(data.distributorId) : undefined,
      belongsToDealerId: data.dealerId ? BigInt(data.dealerId) : undefined
    };

    await farmerRepository.updateFarmer(farmerId, farmer.userId, profileData, userData);
    
    await activityLogService.log(auth.userId, "update", "farmer" as any, farmerId, { name: data.name });
    
    return farmerRepository.findById(farmerId);
  },

  async delete(auth: Express.Request["auth"], farmerId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role !== "admin") throw new AppError(403, "Forbidden", "forbidden");

    const farmer = await farmerRepository.findById(farmerId);
    if (!farmer) throw new AppError(404, "Farmer profile not found", "farmerNotFound");

    await farmerRepository.deleteFarmer(farmer.userId);
    await activityLogService.log(auth.userId, "delete", "farmer" as any, farmerId);
    
    return { success: true, message: "Farmer deactivated successfully." };
  }
};
