import type { Request, Response, NextFunction } from "express";
import { AppError } from "../lib/AppError";

export function notFoundHandler(req: Request, _res: Response, next: NextFunction) {
  next(new AppError(404, `Route not found: ${req.method} ${req.originalUrl}`, "routeNotFound"));
}

export function errorHandler(error: unknown, _req: Request, res: Response, _next: NextFunction) {
  const err = error as Error & { statusCode?: number; code?: string };

  if (err.name === "ZodError" || (err as any).issues) {
    const issues = (err as any).issues || [];
    const details = issues.map((i: any) => `${i.path.join(".")}: ${i.message}`).join(", ");
    return res.status(400).json({
      success: false,
      error: {
        code: "validationError",
        message: `Validation failed: ${details}`
      }
    });
  }

  if (err.name === "PrismaClientKnownRequestError" || (err.code && typeof err.code === "string" && err.code.startsWith("P"))) {
    if (err.code === "P2002") {
      const meta = (err as any).meta;
      let targetStr = "";
      if (meta) {
        if (meta.target) {
          targetStr = Array.isArray(meta.target) ? meta.target.join(",") : String(meta.target);
        } else if (meta.driverAdapterError?.cause?.constraint?.index) {
          targetStr = String(meta.driverAdapterError.cause.constraint.index);
        } else if (meta.driverAdapterError?.cause?.originalMessage) {
          targetStr = String(meta.driverAdapterError.cause.originalMessage);
        }
      }

      let msg = "A record with this value already exists.";
      if (targetStr) {
        if (targetStr.includes("deviceUid")) {
          msg = "A valve with this Device UID already exists.";
        } else if (targetStr.includes("valveNumber") || targetStr.includes("slaveBoardId") || targetStr.includes("slaveBoardId_valveNumber")) {
          msg = "A valve with this position/number already exists on this board.";
        } else {
          msg = `Unique constraint failed on: ${targetStr}`;
        }
      }
      return res.status(400).json({
        success: false,
        error: {
          code: "uniqueConstraintViolation",
          message: msg
        }
      });
    }
    if (err.code === "P2003") {
      return res.status(400).json({
        success: false,
        error: {
          code: "foreignKeyConstraintViolation",
          message: "Foreign key constraint failed. Check referenced IDs."
        }
      });
    }
  }

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
