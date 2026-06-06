import { prisma } from "../db/prisma";
import { commandService } from "./commandService";
import { env } from "../config/env";
import { emitFieldEvent, emitAdminEvent } from "../realtime/socket";

// Helper to construct mock admin auth context for a farmer's system command
async function getSystemAuth(farmerId: bigint) {
  const farmerUser = await prisma.user.findFirst({
    where: { farmer: { id: farmerId } }
  });
  return {
    userId: farmerUser ? farmerUser.id : BigInt(1),
    role: "admin" as const,
    farmerId
  };
}

// Helper to resolve current time/date details in target timezone
function getCurrentTimeInTimezone(timezone: string): { hhmm: string; dayOfWeek: string; dateStr: string } {
  const d = new Date();
  
  // Format HH:MM (24-hour)
  const timeParts = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    hour: "2-digit",
    minute: "2-digit",
    hour12: false
  }).formatToParts(d);
  const hour = timeParts.find(p => p.type === 'hour')?.value || "00";
  const minute = timeParts.find(p => p.type === 'minute')?.value || "00";
  const hhmm = `${hour}:${minute}`;

  // Weekday name in lowercase (e.g. "monday")
  const dayOfWeek = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    weekday: "long"
  }).format(d).toLowerCase();

  // Date string YYYY-MM-DD
  const dateParts = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(d);
  const year = dateParts.find(p => p.type === 'year')?.value;
  const month = dateParts.find(p => p.type === 'month')?.value;
  const day = dateParts.find(p => p.type === 'day')?.value;
  const dateStr = `${year}-${month}-${day}`;

  return { hhmm, dayOfWeek, dateStr };
}

export async function checkOfflineControllers() {
  try {
    const threshold = new Date(Date.now() - env.HEARTBEAT_OFFLINE_THRESHOLD_SECONDS * 1000);
    const affected = await prisma.masterController.findMany({
      where: {
        status: "online",
        lastHeartbeatAt: { lt: threshold }
      }
    });

    for (const mc of affected) {
      await prisma.masterController.update({
        where: { id: mc.id },
        data: { status: "offline" }
      });

      emitFieldEvent(mc.fieldId, "masterHeartbeat", {
        masterControllerId: mc.id.toString(),
        status: "offline",
        lastHeartbeatAt: mc.lastHeartbeatAt
      });

      emitAdminEvent("masterHeartbeat", {
        masterControllerId: mc.id.toString(),
        status: "offline",
        lastHeartbeatAt: mc.lastHeartbeatAt
      });

      console.log(`Controller ${mc.deviceUid} went offline due to timeout.`);
    }
  } catch (error) {
    console.error("Error checking offline controllers:", error);
  }
}

export async function processActiveSchedules() {
  try {
    const schedules = await prisma.irrigationSchedule.findMany({
      where: { status: "active" }
    });

    for (const schedule of schedules) {
      const timezone = schedule.timezone || "Asia/Kolkata";
      const { hhmm, dayOfWeek, dateStr } = getCurrentTimeInTimezone(timezone);

      // Check if start time matches
      if (hhmm !== schedule.startTime) continue;

      // Check repeating days
      let shouldRun = false;
      if (schedule.repeatType === "once") {
        shouldRun = true;
      } else if (schedule.repeatType === "daily") {
        shouldRun = true;
      } else if (schedule.repeatType === "weekly" || schedule.repeatType === "customDays") {
        const days = schedule.repeatDays as string[] | null;
        if (days && days.includes(dayOfWeek)) {
          shouldRun = true;
        }
      }

      if (!shouldRun) continue;

      // Ensure no run already started in the last 5 minutes for this schedule
      const startRange = new Date(Date.now() - 5 * 60 * 1000);
      const existingRun = await prisma.scheduleRun.findFirst({
        where: {
          scheduleId: schedule.id,
          createdAt: { gte: startRange }
        }
      });

      if (existingRun) continue;

      console.log(`Triggering schedule: ${schedule.name} (${schedule.id})`);

      const auth = await getSystemAuth(schedule.farmerId);
      const scheduleType = schedule.scheduleType;
      const zoneIds = schedule.zoneIds ? (schedule.zoneIds as number[]).map(BigInt) : [];

      if (scheduleType === "timerBased" && zoneIds.length > 0) {
        // Sequentially active zones - Start with index 0
        const firstZoneId = zoneIds[0];
        const cmd = await commandService.createZoneCommand(auth, firstZoneId, "open", "schedule");

        await prisma.scheduleRun.create({
          data: {
            scheduleId: schedule.id,
            status: "running",
            scheduledFor: new Date(),
            startedAt: new Date(),
            openCommandId: cmd.id,
            metadata: {
              currentZoneIndex: 0,
              commandIds: [cmd.id.toString()]
            }
          }
        });
      } else {
        // Time-based (parallel) zones or single target
        const cmdIds: string[] = [];
        let primaryOpenCommandId: bigint | null = null;

        if (zoneIds.length > 0) {
          for (const zoneId of zoneIds) {
            const cmd = await commandService.createZoneCommand(auth, zoneId, "open", "schedule");
            cmdIds.push(cmd.id.toString());
            if (!primaryOpenCommandId) primaryOpenCommandId = cmd.id;
          }
        } else {
          // single target (zone/valve)
          if (schedule.targetType === "zone") {
            const cmd = await commandService.createZoneCommand(auth, schedule.targetId, "open", "schedule");
            cmdIds.push(cmd.id.toString());
            primaryOpenCommandId = cmd.id;
          } else if (schedule.targetType === "valve") {
            const cmd = await commandService.createValveCommand(auth, schedule.targetId, "open", "schedule");
            cmdIds.push(cmd.id.toString());
            primaryOpenCommandId = cmd.id;
          }
        }

        await prisma.scheduleRun.create({
          data: {
            scheduleId: schedule.id,
            status: "running",
            scheduledFor: new Date(),
            startedAt: new Date(),
            openCommandId: primaryOpenCommandId,
            metadata: {
              commandIds: cmdIds
            }
          }
        });
      }

      // If "once", pause schedule so it doesn't trigger again
      if (schedule.repeatType === "once") {
        await prisma.irrigationSchedule.update({
          where: { id: schedule.id },
          data: { status: "paused" }
        });
      }
    }
  } catch (error) {
    console.error("Error processing active schedules:", error);
  }
}

export async function manageRunningRuns() {
  try {
    const runs = await prisma.scheduleRun.findMany({
      where: { status: "running" },
      include: { schedule: true }
    });

    for (const run of runs) {
      const startedAt = run.startedAt || run.createdAt;
      const elapsedMinutes = (Date.now() - startedAt.getTime()) / 60000;
      const auth = await getSystemAuth(run.schedule.farmerId);
      const metadata = (run.metadata as any) || {};
      const commandIds = metadata.commandIds || [];

      if (run.schedule.scheduleType === "timerBased") {
        // Sequential schedule management
        const zoneIds = run.schedule.zoneIds ? (run.schedule.zoneIds as number[]).map(BigInt) : [];
        const durationPerZone = run.schedule.durationMinutes;
        const targetIndex = Math.floor(elapsedMinutes / durationPerZone);
        const previousIndex = metadata.currentZoneIndex !== undefined ? Number(metadata.currentZoneIndex) : 0;

        if (targetIndex !== previousIndex) {
          // Time to close previous zone
          if (previousIndex < zoneIds.length) {
            const prevZoneId = zoneIds[previousIndex];
            const closeCmd = await commandService.createZoneCommand(auth, prevZoneId, "close", "schedule");
            commandIds.push(closeCmd.id.toString());
          }

          // Time to open next zone, or complete the run
          if (targetIndex < zoneIds.length) {
            const nextZoneId = zoneIds[targetIndex];
            const openCmd = await commandService.createZoneCommand(auth, nextZoneId, "open", "schedule");
            commandIds.push(openCmd.id.toString());

            await prisma.scheduleRun.update({
              where: { id: run.id },
              data: {
                metadata: {
                  currentZoneIndex: targetIndex,
                  commandIds
                }
              }
            });
            console.log(`Sequential schedule ${run.schedule.name}: advanced to Zone index ${targetIndex}`);
          } else {
            // Sequence completed
            await prisma.scheduleRun.update({
              where: { id: run.id },
              data: {
                status: "completed",
                completedAt: new Date(),
                metadata: {
                  currentZoneIndex: targetIndex,
                  commandIds
                }
              }
            });
            console.log(`Sequential schedule ${run.schedule.name} run completed.`);
          }
        }
      } else {
        // Standard Time-Based Schedule
        if (elapsedMinutes >= run.schedule.durationMinutes) {
          const zoneIds = run.schedule.zoneIds ? (run.schedule.zoneIds as number[]).map(BigInt) : [];
          let primaryCloseCommandId: bigint | null = null;

          if (zoneIds.length > 0) {
            for (const zoneId of zoneIds) {
              const cmd = await commandService.createZoneCommand(auth, zoneId, "close", "schedule");
              commandIds.push(cmd.id.toString());
              if (!primaryCloseCommandId) primaryCloseCommandId = cmd.id;
            }
          } else {
            // single target close
            if (run.schedule.targetType === "zone") {
              const cmd = await commandService.createZoneCommand(auth, run.schedule.targetId, "close", "schedule");
              commandIds.push(cmd.id.toString());
              primaryCloseCommandId = cmd.id;
            } else if (run.schedule.targetType === "valve") {
              const cmd = await commandService.createValveCommand(auth, run.schedule.targetId, "close", "schedule");
              commandIds.push(cmd.id.toString());
              primaryCloseCommandId = cmd.id;
            }
          }

          await prisma.scheduleRun.update({
            where: { id: run.id },
            data: {
              status: "completed",
              completedAt: new Date(),
              closeCommandId: primaryCloseCommandId,
              metadata: {
                commandIds
              }
            }
          });
          console.log(`Time-based schedule ${run.schedule.name} run completed.`);
        }
      }
    }
  } catch (error) {
    console.error("Error managing running schedule runs:", error);
  }
}

// Background loop runner
let intervalId: NodeJS.Timeout | null = null;

export function startScheduler() {
  if (intervalId) return;

  // Run every 60 seconds
  intervalId = setInterval(async () => {
    console.log("Scheduler tick: executing offline check, schedule checks, and sequential run updates...");
    await checkOfflineControllers();
    await processActiveSchedules();
    await manageRunningRuns();
  }, 60000);

  // Run immediately on boot for offline check and running runs check
  void checkOfflineControllers();
  void manageRunningRuns();
}

export function stopScheduler() {
  if (intervalId) {
    clearInterval(intervalId);
    intervalId = null;
  }
}
