import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().default(4000),
  CORS_ORIGIN: z.string().default("*"),
  JWT_SECRET: z.string().min(16),
  JWT_EXPIRES_IN: z.string().default("7d"),

  DATABASE_HOST: z.string().default("localhost"),
  DATABASE_PORT: z.coerce.number().default(3306),
  DATABASE_USER: z.string(),
  DATABASE_PASSWORD: z.string(),
  DATABASE_NAME: z.string(),
  DATABASE_CONNECTION_LIMIT: z.coerce.number().default(5),

  REDIS_HOST: z.string().default("localhost"),
  REDIS_PORT: z.coerce.number().default(6379),
  REDIS_PASSWORD: z.string().optional().default(""),

  MQTT_URL: z.string().default("mqtt://localhost:1883"),
  MQTT_USERNAME: z.string().optional().default(""),
  MQTT_PASSWORD: z.string().optional().default(""),
  MQTT_CLIENT_ID: z.string().default("drip-api-server"),

  MANUAL_COMMAND_EXPIRY_MINUTES: z.coerce.number().default(30),
  SCHEDULE_COMMAND_EXPIRY_MINUTES: z.coerce.number().default(10),
  MAX_COMMAND_RETRIES: z.coerce.number().default(3),
  ZONE_VALVE_DELAY_SECONDS: z.coerce.number().default(2),
  HEARTBEAT_OFFLINE_THRESHOLD_SECONDS: z.coerce.number().default(120)
});

export const env = envSchema.parse(process.env);

export const corsOrigins =
  env.CORS_ORIGIN === "*"
    ? "*"
    : env.CORS_ORIGIN.split(",").map((origin) => origin.trim()).filter(Boolean);
