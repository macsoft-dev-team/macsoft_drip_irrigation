import { Server } from "socket.io";
import type { Server as HttpServer } from "node:http";
import { env, corsOrigins } from "../config/env";
import { toJsonSafe } from "../lib/http";

let io: Server | undefined;

export function initSocket(server: HttpServer) {
  io = new Server(server, {
    cors: {
      origin: (origin, callback) => {
        if (!origin || env.CORS_ORIGIN === "*" || corsOrigins.includes(origin) || env.NODE_ENV === "development") {
          callback(null, true);
        } else {
          callback(new Error("Not allowed by CORS"));
        }
      },
      credentials: true
    }
  });

  io.on("connection", (socket) => {
    socket.on("joinFarmer", (farmerId: string) => {
      socket.join(`farmer:${farmerId}`);
    });

    socket.on("joinField", (fieldId: string) => {
      socket.join(`field:${fieldId}`);
    });

    socket.on("joinAdmin", () => {
      socket.join("admin");
    });
  });

  return io;
}

export function emitFarmerEvent(farmerId: bigint, event: string, payload: unknown) {
  io?.to(`farmer:${farmerId.toString()}`).emit(event, toJsonSafe(payload));
}

export function emitFieldEvent(fieldId: bigint, event: string, payload: unknown) {
  io?.to(`field:${fieldId.toString()}`).emit(event, toJsonSafe(payload));
}

export function emitAdminEvent(event: string, payload: unknown) {
  io?.to("admin").emit(event, toJsonSafe(payload));
}
