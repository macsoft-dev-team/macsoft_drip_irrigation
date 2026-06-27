import type { Response } from "express";

export function toJsonSafe(value: unknown): unknown {
  return JSON.parse(
    JSON.stringify(value, (_key, item) => {
      if (typeof item === "bigint") return item.toString();
      return item;
    })
  );
}

export function ok(res: Response, data: unknown, statusCode = 200) {
  return res.status(statusCode).json({
    success: true,
    data: toJsonSafe(data)
  });
}

export function created(res: Response, data: unknown) {
  return ok(res, data, 201);
}
