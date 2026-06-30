import { commandDispatchService } from "../services/commandDispatchService";

// Bypassing Redis queue for now; we will add it later.
export async function enqueueCommand(commandId: bigint, _options?: any) {
  // Execute the command dispatching directly in the background
  void commandDispatchService.dispatchCommand(commandId).catch((error) => {
    console.error("Direct command dispatch failed for commandId:", commandId.toString(), error);
  });
}

export function startCommandWorker() {
  console.log("Redis command worker is disabled for now.");
  return null;
}

