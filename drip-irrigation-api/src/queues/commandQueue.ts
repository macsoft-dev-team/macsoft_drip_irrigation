import { Queue, Worker, JobsOptions } from "bullmq";
import { redisConnection } from "./redis";
import { env } from "../config/env";
import { commandDispatchService } from "../services/commandDispatchService";

export const commandQueue = new Queue("commands", {
  connection: redisConnection as any
});

export async function enqueueCommand(commandId: bigint, options: JobsOptions = {}) {
  await commandQueue.add(
    "dispatchCommand",
    { commandId: commandId.toString() },
    {
      attempts: env.MAX_COMMAND_RETRIES,
      backoff: { type: "exponential", delay: 5000 },
      removeOnComplete: 1000,
      removeOnFail: 1000,
      ...options
    }
  );
}

export function startCommandWorker() {
  const worker = new Worker(
    "commands",
    async (job) => {
      const commandId = BigInt(job.data.commandId);
      await commandDispatchService.dispatchCommand(commandId);
    },
    {
      connection: redisConnection as any,
      concurrency: 10
    }
  );

  worker.on("failed", (job, error) => {
    console.error("Command worker failed", job?.id, error);
  });

  return worker;
}
