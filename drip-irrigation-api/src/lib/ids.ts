import crypto from "node:crypto";
import { AppError } from "./AppError";

export function uid(prefix: string) {
  return `${prefix}_${Date.now().toString(36)}_${crypto.randomBytes(8).toString("hex")}`;
}

export function parseBigIntId(value: string | undefined, name = "id"): bigint {
  if (!value || !/^\d+$/.test(value)) {
    throw new AppError(400, `Invalid ${name}`, "invalidId");
  }
  return BigInt(value);
}
