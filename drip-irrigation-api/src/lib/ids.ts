import crypto from "node:crypto";
import { AppError } from "./AppError";

export function uid(prefix: string) {
  return `${prefix}_${Date.now().toString(36)}_${crypto.randomBytes(8).toString("hex")}`;
}

export function parseBigIntId(value: any, name = "id"): bigint {
  const strVal = typeof value === "string" ? value : String(value || "");
  if (!strVal || !/^\d+$/.test(strVal)) {
    throw new AppError(400, `Invalid ${name}`, "invalidId");
  }
  return BigInt(strVal);
}
