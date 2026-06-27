import { prisma } from "../src/db/prisma.js";
import { enqueueCommand } from "../src/queues/commandQueue.js";
import { uid } from "../src/lib/ids.js";

async function main() {
  console.log("[TEST] Querying John and Valves...");
  const user = await prisma.user.findFirst({
    where: { phone: "8888888888" },
    include: { farmer: true }
  });

  const valves = await prisma.valve.findMany({
    where: {
      name: { in: ["Valve A", "Valve D"] }
    }
  });

  if (!user || !user.farmer || valves.length < 2) {
    console.error("[TEST] Error: Seed data not found!");
    process.exit(1);
  }

  const master = await prisma.masterController.findFirst({
    where: { deviceUid: "MASTER-001" }
  });

  if (!master) {
    console.error("[TEST] Error: MASTER-001 not found!");
    process.exit(1);
  }

  console.log("[TEST] Creating multi-valve command targeting Slave 1 (Coil 0 & Coil 1)...");
  
  const commandUid = uid("cmd");
  const command = await prisma.command.create({
    data: {
      commandUid,
      farmerId: user.farmer.id,
      fieldId: BigInt(1),
      masterControllerId: master.id,
      requestedByUserId: user.id,
      targetType: "zone", // simulate zone target to allow multiple items
      targetId: BigInt(1),
      action: "open",
      source: "app",
      status: "queued",
      items: {
        create: valves.map((valve, index) => ({
          valveId: valve.id,
          sequenceNumber: index + 1,
          action: "open",
          status: "pending"
        }))
      }
    }
  });

  console.log("==================================================================");
  console.log(`[TEST] Command created! ID: ${command.id}, UID: ${command.commandUid}`);
  console.log("==================================================================");

  // Dispatch it directly
  await enqueueCommand(command.id);

  console.log("[TEST] Waiting for simulator to receive and process...");
  await new Promise((resolve) => setTimeout(resolve, 5000));

  console.log("[TEST] Checking command status in DB...");
  const updated = await prisma.command.findUnique({
    where: { id: command.id },
    include: { items: true }
  });

  console.log("==================================================================");
  console.log(`[TEST] Final Command Status: ${updated?.status}`);
  console.log("==================================================================");
  
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
