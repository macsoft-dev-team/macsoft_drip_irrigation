// mqtt-simulator.js

const mqtt = require("mqtt");
const axios = require("axios");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") ,quiet: true});

// ================= CONFIG =================
const MQTT_URL = "mqtt://mqtt.macsoftautomations.in:1883";
const MQTT_USERNAME = "admin";
const MQTT_PASSWORD = "admin";

const API_BASE_URL = "https://hns.macsoftautomations.in/api"; // adjust if needed
const ADMIN_EMAIL = "superadmin@macsoft.com";
const ADMIN_PASSWORD = "admin123";

const INTERVAL = 2000; // ms

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

// ================= LOGIN =================
async function login() {
  const res = await axios.post(`${API_BASE_URL}/auth/login`, {
    any: ADMIN_EMAIL,
    password: ADMIN_PASSWORD
  });
  return res.data.token;
}

// ================= FETCH DEVICES =================
async function getDevices(token) {
  const res = await axios.get(`${API_BASE_URL}/devices`, {
    headers: { Authorization: `Bearer ${token}` },
    params: { skip: 0, take: 50 }
  });

  // Response shape: { success, data: { devices: [...], totalCount } }
  const list = res.data?.data?.devices || [];
  return list.map(d => String(d.deviceUid || d.imeinumber));
}

// ================= START =================
client.on("connect", async () => {
  console.log("🚀 Simulator connected to MQTT");

  let token;
  try {
    token = await login();
    console.log("🔑 Logged in as super admin");
  } catch (err) {
    console.error("❌ Login failed:", err.response?.data?.message || err.message);
    process.exit(1);
  }

  let devices;
  try {
    devices = await getDevices(token);
  } catch (err) {
    console.error("❌ Failed to fetch devices:", err.response?.data?.message || err.message);
    process.exit(1);
  }

  if (devices.length === 0) {
    console.error("❌ No devices found");
    process.exit(1);
  }

  console.log(`📦 Loaded ${devices.length} devices`);

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
process.on("SIGINT", () => {
  console.log("Shutting down simulator...");
  process.exit(0);
});