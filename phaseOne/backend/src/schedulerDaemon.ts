import "dotenv/config";
import { startScheduler } from "./services/scheduler";
import { prisma } from "./db/prisma";

console.log("Starting Standalone Scheduler Daemon...");

startScheduler();

async function shutdown(signal: string) {
  console.log(`${signal} received. Shutting down Scheduler Daemon.`);
  try {
    await prisma.$disconnect();
    console.log("Database disconnected successfully.");
  } catch (error) {
    console.error("Error during database disconnection:", error);
  }
  process.exit(0);
}

process.on("SIGINT", () => void shutdown("SIGINT"));
process.on("SIGTERM", () => void shutdown("SIGTERM"));
