import express from "express";
import cors from "cors";
import helmet from "helmet";
import { corsOrigins } from "./config/env";
import { apiRoutes } from "./routes";
import { errorHandler, notFoundHandler } from "./middleware/errorHandler";
import { requestLogger } from "./middleware/requestLogger";

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(cors({
    origin: corsOrigins === "*" ? "*" : corsOrigins,
    credentials: true
  }));
  app.use(express.json({ limit: "1mb" }));
  app.use(requestLogger);

  app.get("/health", (_req, res) => {
    res.json({
      success: true,
      data: {
        status: "ok",
        service: "drip-irrigation-saas-api",
        time: new Date().toISOString()
      }
    });
  });

  app.use("/api/v1", apiRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
