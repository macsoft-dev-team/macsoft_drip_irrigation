import type { Request, Response, NextFunction } from "express";
import { AppError } from "../lib/AppError";

export function notFoundHandler(req: Request, _res: Response, next: NextFunction) {
  next(new AppError(404, `Route not found: ${req.method} ${req.originalUrl}`, "routeNotFound"));
}

export function errorHandler(error: unknown, _req: Request, res: Response, _next: NextFunction) {
  const err = error as Error & { statusCode?: number; code?: string };

  const statusCode = err.statusCode ?? 500;
  const code = err.code ?? "internalServerError";
  const message = statusCode === 500 ? "Internal server error" : err.message;

  if (statusCode === 500) {
    console.error(err);
  }

  res.status(statusCode).json({
    success: false,
    error: {
      code,
      message
    }
  });
}
