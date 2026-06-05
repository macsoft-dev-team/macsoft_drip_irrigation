import { z } from "zod";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { hashPassword, verifyPassword } from "../lib/password";
import { signJwt } from "../lib/jwt";

const registerFarmerSchema = z.object({
  name: z.string().min(2).max(150),
  phone: z.string().min(8).max(20),
  email: z.string().email().optional(),
  password: z.string().min(8),
  address: z.string().optional(),
  village: z.string().optional(),
  district: z.string().optional(),
  state: z.string().optional(),
  pincode: z.string().optional()
});

const loginSchema = z.object({
  phone: z.string().min(8).max(20),
  password: z.string().min(1)
});

export const authService = {
  async registerFarmer(input: unknown) {
    const data = registerFarmerSchema.parse(input);

    const existing = await prisma.user.findFirst({
      where: {
        OR: [
          { phone: data.phone },
          ...(data.email ? [{ email: data.email }] : [])
        ]
      }
    });

    if (existing) {
      throw new AppError(409, "User already exists", "userExists");
    }

    const passwordHash = await hashPassword(data.password);

    const user = await prisma.user.create({
      data: {
        name: data.name,
        phone: data.phone,
        email: data.email,
        passwordHash,
        role: "farmer",
        farmer: {
          create: {
            address: data.address,
            village: data.village,
            district: data.district,
            state: data.state,
            pincode: data.pincode
          }
        }
      },
      include: { farmer: true }
    });

    const token = signJwt({ userId: user.id.toString(), role: user.role });

    return { token, user };
  },

  async login(input: unknown) {
    const data = loginSchema.parse(input);

    const user = await prisma.user.findUnique({
      where: { phone: data.phone },
      include: { farmer: true, distributor: true }
    });

    if (!user || user.status !== "active") {
      throw new AppError(401, "Invalid phone or password", "invalidCredentials");
    }

    const valid = await verifyPassword(data.password, user.passwordHash);
    if (!valid) {
      throw new AppError(401, "Invalid phone or password", "invalidCredentials");
    }

    const token = signJwt({ userId: user.id.toString(), role: user.role });
    return { token, user };
  },

  async me(userId: bigint) {
    return prisma.user.findUnique({
      where: { id: userId },
      include: { farmer: true, distributor: true }
    });
  }
};
