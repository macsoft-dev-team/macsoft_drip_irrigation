// mqtt-simulator.js

const mqtt = require("mqtt");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env"), quiet: true });

const { prisma } = require("../prisma/client");

// ================= CONFIG =================
const MQTT_URL = process.env.MQTT_BROKER_URL || "mqtt://localhost:1883";
const MQTT_USERNAME = process.env.MQTT_USERNAME;
const MQTT_PASSWORD = process.env.MQTT_PASSWORD;

const INTERVAL = 5000; // ms

// ================= MQTT =================
const client = mqtt.connect(MQTT_URL, {
  username: MQTT_USERNAME,
  password: MQTT_PASSWORD
});

// ================= RANDOM HELPERS =================
function rand(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function generatePayload() {
  const pumpStatus = () => rand(0, 3); // 0=VFD, 1=DOL, 2=STOP, 3=SERVICE
  return {
    // System
    PRS: parseFloat((Math.random() * 7 + 1).toFixed(2)),  // Actual pressure 1–8 bar
    VFD: rand(25, 50),                                     // VFD output frequency Hz

    // Fault & status
    FLT: Math.random() < 0.05 ? rand(1, 15) : 0,
    STS: rand(0, 3),

    // Pump status (0=VFD, 1=DOL, 2=STOP, 3=SERVICE)
    P1S: pumpStatus(),
    P2S: pumpStatus(),
    P3S: pumpStatus(),
    P4S: pumpStatus(),
    P5S: pumpStatus(),

    // Runtime minutes per pump
    P1R: rand(0, 50000),
    P2R: rand(0, 50000),
    P3R: rand(0, 50000),
    P4R: rand(0, 50000),
    P5R: rand(0, 50000),

    // Starts per hour per pump
    S1H: rand(0, 6),
    S2H: rand(0, 6),
    S3H: rand(0, 6),
    S4H: rand(0, 6),
    S5H: rand(0, 6),

    // Current per pump (A)
    IC1: parseFloat((Math.random() * 8 + 4).toFixed(1)),
    IC2: parseFloat((Math.random() * 8 + 4).toFixed(1)),
    IC3: parseFloat((Math.random() * 8 + 4).toFixed(1)),

    // Voltage per pump (V)
    IV1: rand(218, 242),
    IV2: rand(218, 242),
    IV3: rand(218, 242),

    RSI: rand(-110, -60)
  };
}

// ================= LOAD DEVICES FROM DB =================
async function getDevices() {
  const devices = await prisma.device.findMany({
    select: { deviceUid: true },
    take: 50 // limit for simulation
  });

  return devices.map(d => String(d.deviceUid));
}

// ================= START =================
client.on("connect", async () => {
  console.log("🚀 Simulator connected");

  let devices = await getDevices();

  if (devices.length === 0) {
    console.error("❌ No devices found in DB");
    process.exit(1);
  }

  console.log(`📦 Loaded ${devices.length} devices from DB`);

  // Refresh device list every 30s to auto-discover newly provisioned devices
  setInterval(async () => {
    try {
      const updated = await getDevices();
      const newOnes = updated.filter(id => !devices.includes(id));
      if (newOnes.length > 0) {
        console.log(`🆕 ${newOnes.length} new device(s) discovered: ${newOnes.join(", ")}`);
      }
      devices = updated;
    } catch (err) {
      console.error("Device refresh error:", err.message);
    }
  }, 30000);

  // publish telemetry
  setInterval(() => {
    devices.forEach((deviceId) => {
      const payload = generatePayload();

      client.publish(
        `device/${deviceId}/data`,
        JSON.stringify(payload)
      );

      console.log(`📤 ${deviceId}`);
    });
  }, INTERVAL);

  // simulate cmd response
  setInterval(() => {
    const deviceId = devices[rand(0, devices.length - 1)];

    client.publish(
      `device/${deviceId}/cmd/res`,
      JSON.stringify({ success: Math.random() > 0.2 })
    );

    console.log(`✅ CMD RES → ${deviceId}`);
  }, 5000);
});

// ================= ERROR =================
client.on("error", (err) => {
  console.error("MQTT Error:", err.message);
});

// ================= CLEANUP =================
process.on("SIGINT", async () => {
  console.log("Shutting down simulator...");
  await prisma.$disconnect();
  process.exit(0);
});