import { createUserSchema, updateUserSchema, updateStatusSchema } from "../validations/userValidation";
import { userRepository } from "../repositories/userRepository";
import { AppError } from "../lib/AppError";
import { hashPassword } from "../lib/password";

export const userService = {
  async list(auth: Express.Request["auth"]) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    if (auth.role === "admin" && !auth.distributorId && !auth.dealerId) {
      return userRepository.listAll();
    }

    return userRepository.listTenantUsers(auth.distributorId || null, auth.dealerId || null, auth.userId);
  },

  async create(auth: Express.Request["auth"], input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = createUserSchema.parse(input);

    const existing = await userRepository.findByPhoneOrEmail(data.phone, data.email);
    if (existing) {
      throw new AppError(409, "User already exists", "userExists");
    }

    let belongsToDistributorId: bigint | null = null;
    let belongsToDealerId: bigint | null = null;

    if (auth.role === "admin" && !auth.distributorId && !auth.dealerId) {
      belongsToDistributorId = data.belongsToDistributorId ? BigInt(data.belongsToDistributorId) : null;
      belongsToDealerId = data.belongsToDealerId ? BigInt(data.belongsToDealerId) : null;
    } else {
      belongsToDistributorId = auth.distributorId || null;
      belongsToDealerId = auth.dealerId || null;
      if (data.role === "admin") {
        throw new AppError(403, "Tenant admins cannot create platform admins", "forbidden");
      }
    }

    const passwordHash = await hashPassword(data.password);

    return userRepository.createUser({
      name: data.name,
      phone: data.phone,
      email: data.email,
      passwordHash,
      role: data.role,
      hasWholesalePricing: data.hasWholesalePricing,
      belongsToDistributorId,
      belongsToDealerId,
      ...(data.role === "farmer"
          ? {
              farmer: {
                create: {}
              }
            }
          : {})
    });
  },

  async get(auth: Express.Request["auth"], userId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    const user = await userRepository.findById(userId);
    if (!user) throw new AppError(404, "User not found", "userNotFound");

    if (auth.role !== "admin" || auth.distributorId || auth.dealerId) {
      const isSameDistributor = auth.distributorId && user.belongsToDistributorId === auth.distributorId;
      const isSameDealer = auth.dealerId && user.belongsToDealerId === auth.dealerId;
      const isSelf = user.id === auth.userId;
      if (!isSameDistributor && !isSameDealer && !isSelf) {
        throw new AppError(403, "Forbidden", "forbidden");
      }
    }

    return user;
  },

  async update(auth: Express.Request["auth"], userId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const targetUser = await userRepository.findById(userId);
    if (!targetUser) {
      throw new AppError(404, "User not found", "userNotFound");
    }

    if (auth.role !== "admin" || auth.distributorId || auth.dealerId) {
      const isSameDistributor = auth.distributorId && targetUser.belongsToDistributorId === auth.distributorId;
      const isSameDealer = auth.dealerId && targetUser.belongsToDealerId === auth.dealerId;
      const isSelf = targetUser.id === auth.userId;

      if (!isSameDistributor && !isSameDealer && !isSelf) {
        throw new AppError(403, "Forbidden", "forbidden");
      }
    }

    const data = updateUserSchema.parse(input);

    return userRepository.updateUser(userId, {
      name: data.name,
      email: data.email,
      role: data.role,
      status: data.status,
      hasWholesalePricing: data.hasWholesalePricing,
      belongsToDistributorId: data.belongsToDistributorId ? BigInt(data.belongsToDistributorId) : undefined,
      belongsToDealerId: data.belongsToDealerId ? BigInt(data.belongsToDealerId) : undefined
    });
  },

  async updateStatus(auth: Express.Request["auth"], userId: bigint, input: unknown) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");

    const allowedRoles = ["admin", "tenant_admin"];
    if (!allowedRoles.includes(auth.role)) {
      throw new AppError(403, "Forbidden", "forbidden");
    }

    const data = updateStatusSchema.parse(input);
    return userRepository.updateUser(userId, { status: data.status });
  },

  async delete(auth: Express.Request["auth"], userId: bigint) {
    if (!auth) throw new AppError(401, "Authentication required", "authRequired");
    if (auth.role !== "admin") throw new AppError(403, "Forbidden", "forbidden");

    const targetUser = await userRepository.findById(userId);
    if (!targetUser) throw new AppError(404, "User not found", "userNotFound");

    return userRepository.deleteUser(userId);
  }
};
