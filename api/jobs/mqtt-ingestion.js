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
        select: { id: true, deviceUid: true, tenantId: true }
    });

    deviceCache.clear();
    // map deviceUid → { id, tenantId } so we can use the correct FK when inserting telemetry
    devices.forEach(d => deviceCache.set(String(d.deviceUid), { id: d.id, tenantId: d.tenantId }));
}

// refresh cache every 60 sec
setInterval(loadDevices, 60000);

// ================= QUEUE =================
const queue = [];

// ================= MQTT CONNECT =================
client.on("connect", async () => {
    await loadDevices();
    client.subscribe("device/+/data");
    client.subscribe("device/+/cmd/res");
});

// ================= MESSAGE HANDLER =================
client.on("message", async (topic, message) => {
    try {
        const parts = topic.split("/");
        const imei = parts[1];

        // validate device and resolve UUID
        let cachedDevice = deviceCache.get(imei);
        if (!cachedDevice) {
            // Cache miss — do an immediate DB lookup in case this is a newly provisioned device
            const found = await prisma.device.findUnique({
                where: { deviceUid: imei },
                select: { id: true, tenantId: true },
            });
            if (!found) {
                return;
            }
            cachedDevice = { id: found.id, tenantId: found.tenantId };
            deviceCache.set(imei, cachedDevice);
        }

        const { id: deviceId, tenantId } = cachedDevice;
        const payload = JSON.parse(message.toString());

        queue.push({
            time: new Date(),
            tenantId,
            deviceId,
            moistureLevel: toFloat(payload.moistureLevel ?? payload.moisture ?? null),
            batteryLevel: toInt(payload.batteryLevel ?? payload.battery ?? null),
            signalStrength: toInt(payload.signalStrength ?? payload.signal ?? null),
            temperature: toFloat(payload.temperature ?? payload.temp ?? null),
            humidity: toFloat(payload.humidity ?? null),
            payload: payload,
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
        await prisma.telemetry.createMany({
            data: batch,
            skipDuplicates: true,
        });

        // Emit each row to subscribed WebSocket clients with mapped properties for backwards compatibility
        batch.forEach((row) => {
            const mapped = {
                ...row,
                // Voltages
                iv1: row.payload.IV1 != null ? Number(row.payload.IV1) : null,
                iv2: row.payload.IV2 != null ? Number(row.payload.IV2) : null,
                iv3: row.payload.IV3 != null ? Number(row.payload.IV3) : null,
                // Currents
                ic1: row.payload.IC1 != null ? Number(row.payload.IC1) : null,
                ic2: row.payload.IC2 != null ? Number(row.payload.IC2) : null,
                ic3: row.payload.IC3 != null ? Number(row.payload.IC3) : null,
                // Faults / Status
                flc: row.payload.FLT ?? row.payload.FLC ?? null,
                sts: row.payload.STS ?? row.payload.STM ?? null,
                // Other fields
                p1s: row.payload.P1S ?? null,
                p2s: row.payload.P2S ?? null,
                p3s: row.payload.P3S ?? null,
                p4s: row.payload.P4S ?? null,
                p5s: row.payload.P5S ?? null,
                p1r: row.payload.P1R ?? null,
                p2r: row.payload.P2R ?? null,
                p3r: row.payload.P3R ?? null,
                p4r: row.payload.P4R ?? null,
                p5r: row.payload.P5R ?? null,
                s1h: row.payload.S1H ?? null,
                s2h: row.payload.S2H ?? null,
                s3h: row.payload.S3H ?? null,
                s4h: row.payload.S4H ?? null,
                s5h: row.payload.S5H ?? null,
                // Signal strength
                rsi: row.signalStrength ?? row.payload.signalStrength ?? row.payload.signal ?? null,
            };
            socketService.emitTelemetry(row.deviceId, mapped);
        });

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
        const cachedDevice = deviceCache.get(imei);
        if (!cachedDevice) return;
        const deviceId = cachedDevice.id;

        const payload = JSON.parse(message.toString());

        await prisma.command.updateMany({
            where: { deviceId, status: "SENT" },
            data: {
                status: payload.success ? "ACKNOWLEDGED" : "FAILED",
                acknowledgedAt: new Date(),
            },
        });

    } catch (err) {
        console.error("CMD response error:", err.message);
    }
});

process.on("SIGINT", async () => {
    console.log("Shutting down...");
    await prisma.$disconnect();
    process.exit(0);
});