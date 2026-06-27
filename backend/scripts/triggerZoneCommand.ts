import { prisma } from "../src/db/prisma.js";
import { commandService } from "../src/services/commandService.js";

async function main() {
  console.log("[TEST] Querying Farmer John...");
  const user = await prisma.user.findFirst({
    where: { phone: "8888888888" },
    include: { farmer: true }
  });

  if (!user || !user.farmer) {
    console.error("[TEST] Error: John is not seeded!");
    process.exit(1);
  }

  const auth = {
    userId: user.id,
    role: user.role,
    farmerId: user.farmer.id
  };

  console.log(`[TEST] Authenticated as User ID: ${auth.userId}, Farmer ID: ${auth.farmerId}`);
  
  // Zone 1 is "Tomato"
  const zoneId = BigInt(1);
  console.log(`[TEST] Creating manual command to OPEN Zone ID: ${zoneId} (Tomato)...`);

  const command = await commandService.createZoneCommand(
    auth as any,
    zoneId,
    "open",
    "app"
  );

  console.log("==================================================================");
  console.log(`[TEST] Command created successfully!`);
  console.log(`Command ID:  ${command.id}`);
  console.log(`Command UID: ${command.commandUid}`);
  console.log(`Status:      ${command.status}`);
  console.log("==================================================================");

  console.log("[TEST] Waiting for simulator to receive and process...");
  await new Promise((resolve) => setTimeout(resolve, 5000));
  
  console.log("[TEST] Checking updated command state in DB...");
  const updatedCommand = await prisma.command.findUnique({
    where: { id: command.id },
    include: { items: true }
  });

  console.log("==================================================================");
  console.log(`[TEST] Final Command Status: ${updatedCommand?.status}`);
  console.log("Items:");
  updatedCommand?.items.forEach((item) => {
    console.log(`  - Valve ID ${item.valveId}: status = ${item.status}`);
  });
  console.log("==================================================================");

  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
