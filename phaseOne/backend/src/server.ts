import http from "node:http";
import { createApp } from "./app";
import { env } from "./config/env";
import { initSocket } from "./realtime/socket";
import { getMqttClient } from "./iot/mqttClient";
import { startCommandWorker } from "./queues/commandQueue";
import { prisma } from "./db/prisma";

const app = createApp();
const server = http.createServer(app);

initSocket(server);
getMqttClient();
startCommandWorker();

server.listen(env.PORT, () => {
  console.log(`Drip Irrigation API running on port ${env.PORT}`);
});

async function shutdown(signal: string) {
  console.log(`${signal} received. Shutting down.`);
  server.close(async () => {
    await prisma.$disconnect();
    process.exit(0);
  });
}

process.on("SIGINT", () => void shutdown("SIGINT"));
process.on("SIGTERM", () => void shutdown("SIGTERM"));

