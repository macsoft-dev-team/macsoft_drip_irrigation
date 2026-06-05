import jwt from "jsonwebtoken";
import { env } from "../config/env";

export type JwtPayload = {
  userId: string;
  role: string;
};

export function signJwt(payload: JwtPayload) {
  return jwt.sign(payload, env.JWT_SECRET, { expiresIn: env.JWT_EXPIRES_IN });
}

export function verifyJwt(token: string) {
  return jwt.verify(token, env.JWT_SECRET) as JwtPayload;
}
