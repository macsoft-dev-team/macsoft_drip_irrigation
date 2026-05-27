// mqtt-ingestion.js

const mqtt = require("mqtt");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") ,quiet: true});
const { prisma } = require("../prisma/client");
const socketService = require("../services/socket");
const MQTT_URL = process.env.MQTT_BROKER_URL || "mqtt://localhost:1883";
const MQTT_USERNAME = process.env.MQTT_USERNAME;
const MQTT_PASSWORD = process.env.MQTT_PASSWORD;
const BATCH_SIZE = 500;
const FLUSH_INTERVAL = 200; // ms

// ================= MQTT CLIENT =================
const client = mqtt.connect(MQTT_URL, {
    username: MQTT_USERNAME,
    password: MQTT_PASSWORD
});

// ================= PARSE HELPERS =================
const toInt = (v) => (v != null && v !== "" ? parseInt(v, 10) : null);
const toFloat = (v) => (v != null && v !== "" ? parseFloat(v) : null);

// ================= DEVICE CACHE =================
const deviceCache = new Map();

async function loadDevices() {
    const devices = await prisma.device.findMany({
        select: { id: true, imeinumber: true }
    });

    deviceCache.clear();
    // map imeinumber → UUID so we can use the correct FK when inserting telemetry
    devices.forEach(d => deviceCache.set(String(d.imeinumber), d.id));

/*     console.log(`Loaded ${deviceCache.size} devices into cache`); */
}

// refresh cache every 60 sec
setInterval(loadDevices, 60000);

// ================= QUEUE =================
const queue = [];

// ================= MQTT CONNECT =================
client.on("connect", async () => {
/*     console.log("MQTT Connected");
 */
    await loadDevices();

    client.subscribe("device/+/data");
    client.subscribe("device/+/cmd/res");

/*     console.log("Subscribed to topics");
 */});

// ================= MESSAGE HANDLER =================
client.on("message", async (topic, message) => {
    try {
        const parts = topic.split("/");
        const imei = parts[1];

        // validate device and resolve UUID
        let deviceId = deviceCache.get(imei);
        if (!deviceId) {
            // Cache miss — do an immediate DB lookup in case this is a newly provisioned device
            const found = await prisma.device.findUnique({
                where: { imeinumber: imei },
                select: { id: true },
            });
            if (!found) {
              //  console.warn(`Unknown device IMEI: ${imei}`);
                return;
            }
            deviceId = found.id;
            deviceCache.set(imei, deviceId);
/*             console.log(`New device discovered and cached: ${imei} → ${deviceId}`);
 */        }

        const payload = JSON.parse(message.toString());

        queue.push({
            deviceId, // UUID — satisfies DeviceTelemetry_deviceId_fkey
            timestamp: new Date(),

            // System pressure from transducer (bar)
            pressure: toFloat(payload.PRS ?? null),

            // VFD output frequency (Hz)
            vfd: toFloat(payload.VFD ?? null),

            // Fault & status
            flt: toInt(payload.FLT ?? payload.FLC ?? null),
            stm: toInt(payload.STS ?? payload.STM ?? null),

            // Pump status (0=VFD, 1=DOL, 2=STOP, 3=SERVICE)
            p1s: toInt(payload.P1S ?? null),
            p2s: toInt(payload.P2S ?? null),
            p3s: toInt(payload.P3S ?? null),
            p4s: toInt(payload.P4S ?? null),
            p5s: toInt(payload.P5S ?? null),

            // Runtime minutes per pump
            p1r: toInt(payload.P1R ?? null),
            p2r: toInt(payload.P2R ?? null),
            p3r: toInt(payload.P3R ?? null),
            p4r: toInt(payload.P4R ?? null),
            p5r: toInt(payload.P5R ?? null),

            // Starts per hour per pump
            s1h: toInt(payload.S1H ?? null),
            s2h: toInt(payload.S2H ?? null),
            s3h: toInt(payload.S3H ?? null),
            s4h: toInt(payload.S4H ?? null),
            s5h: toInt(payload.S5H ?? null),

            // Current per pump (A)
            p1c: toFloat(payload.IC1 ?? null),
            p2c: toFloat(payload.IC2 ?? null),
            p3c: toFloat(payload.IC3 ?? null),
            p4c: toFloat(payload.IC4 ?? null),
            p5c: toFloat(payload.IC5 ?? null),

            // Voltage per pump (V) — or per phase
            p1f: toFloat(payload.IV1 ?? null),
            p2f: toFloat(payload.IV2 ?? null),
            p3f: toFloat(payload.IV3 ?? null),
            p4f: toFloat(payload.IV4 ?? null),
            p5f: toFloat(payload.IV5 ?? null),

            // Full raw payload for audit / future fields
            rawPayload: payload,
        });

        // prevent memory overflow
        if (queue.length > 20000) {
            console.warn("Queue overflow, dropping oldest");
            queue.shift();
        }

    } catch (err) {
        console.error("Invalid message:", err.message);
    }
});

// ================= BATCH WORKER =================
setInterval(async () => {
    if (queue.length === 0) return;

    const batch = queue.splice(0, BATCH_SIZE);

    try {
        await prisma.deviceTelemetry.createMany({
            data: batch,
            skipDuplicates: true,
        });

        // Emit each row to subscribed WebSocket clients
        batch.forEach((row) => socketService.emitTelemetry(row.deviceId, row));

/*         console.log(`Inserted batch: ${batch.length}`);
 */
    } catch (err) {
        console.error("DB insert error:", err.message);

        // requeue on failure
        queue.unshift(...batch);
    }

}, FLUSH_INTERVAL);

// ================= CMD RESPONSE HANDLER =================
client.on("message", async (topic, message) => {
    if (!topic.includes("/cmd/res")) return;

    try {
        const parts = topic.split("/");
        const imei = parts[1];
        // Resolve IMEI → UUID via cache (same cache used by ingestion)
        const deviceId = deviceCache.get(imei);
        if (!deviceId) return;

        const payload = JSON.parse(message.toString());

        await prisma.command.updateMany({
            where: { deviceId, status: "SENT" },
            data: {
                status: payload.success ? "ACK" : "FAILED",
                ackAt: new Date(),
            },
        });

    } catch (err) {
        console.error("CMD response error:", err.message);
    }
});

// ================= ERROR HANDLING =================
/* client.on("error", (err) => {
    console.error("MQTT Error:", err.message);
});
 */
process.on("SIGINT", async () => {
    console.log("Shutting down...");
    await prisma.$disconnect();
    process.exit(0);
});