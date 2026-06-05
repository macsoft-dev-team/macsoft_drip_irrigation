import type { Request, Response, NextFunction } from "express";
import { prisma } from "../db/prisma";
import { AppError } from "../lib/AppError";
import { verifyJwt } from "../lib/jwt";

export async function requireAuth(req: Request, _res: Response, next: NextFunction) {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith("Bearer ")) {
      throw new AppError(401, "Missing bearer token", "missingToken");
    }

    const token = header.slice("Bearer ".length);
    const payload = verifyJwt(token);

    const user = await prisma.user.findUnique({
      where: { id: BigInt(payload.userId) },
      include: {
        farmer: true,
        distributor: true
      }
    });

    if (!user || user.status !== "active") {
      throw new AppError(401, "Invalid or blocked user", "invalidUser");
    }

    req.auth = {
      userId: user.id,
      role: user.role,
      farmerId: user.farmer?.id,
      distributorId: user.distributor?.id
    };

    next();
  } catch (error) {
    next(error);
  }
}

export function requireRole(...roles: string[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.auth) return next(new AppError(401, "Authentication required", "authRequired"));
    if (!roles.includes(req.auth.role)) {
      return next(new AppError(403, "Forbidden", "forbidden"));
    }
    next();
  };
}
