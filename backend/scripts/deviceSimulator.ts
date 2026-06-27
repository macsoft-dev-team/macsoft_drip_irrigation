import mqtt from "mqtt";
import { env } from "../src/config/env.js";

// Standard Modbus RTU CRC16 calculation
function calculateCRC(buffer: Buffer): Buffer {
  let crc = 0xFFFF;
  for (let i = 0; i < buffer.length; i++) {
    crc ^= buffer[i];
    for (let j = 0; j < 8; j++) {
      if ((crc & 1) !== 0) {
        crc = (crc >> 1) ^ 0xA001;
      } else {
        crc >>= 1;
      }
    }
  }
  const crcBuf = Buffer.alloc(2);
  // Modbus CRC is sent Low byte first, then High byte
  crcBuf.writeUInt16LE(crc);
  return crcBuf;
}

function formatHexFrame(buffer: Buffer): string {
  return Array.from(buffer).map(b => b.toString(16).toUpperCase().padStart(2, "0")).join(" ");
}

// Simulated hardware database: Slave Board states (Unit ID -> Coils array)
const slaves: { [key: number]: number[] } = {
  1: Array(8).fill(0), // Slave 1: Coil 0 to 7
  2: Array(8).fill(0), // Slave 2: Coil 0 to 7
  3: Array(8).fill(0), // Slave 3: Coil 0 to 7
};

// Map coil to valve name for user display
const valveNames: { [key: string]: string } = {
  "1-0": "Valve A",
  "2-1": "Valve B",
  "3-2": "Valve C",
  "1-1": "Valve D",
  "2-0": "Valve E"
};

// Connect to MQTT Broker
const client = mqtt.connect(env.MQTT_URL);

client.on("connect", () => {
  console.log("==================================================================");
  console.log(`[DEVICE SIMULATOR] Connected to MQTT Broker: ${env.MQTT_URL}`);
  console.log("[DEVICE SIMULATOR] Simulating Master Controller: MASTER-001");
  console.log("[DEVICE SIMULATOR] Simulating Modbus Slaves: Unit ID 1, 2, 3 on RS485");
  console.log("==================================================================");

  // Subscribe to command topic for MASTER-001
  const commandTopic = "farm/+/field/+/master/MASTER-001/command";
  client.subscribe(commandTopic, (err) => {
    if (err) {
      console.error("[DEVICE SIMULATOR] Subscription failed:", err);
    } else {
      console.log(`[DEVICE SIMULATOR] Subscribed to commands: ${commandTopic}`);
    }
  });

  // Start periodic Heartbeat loop (every 15 seconds) to mark Master Controller ONLINE
  setInterval(() => {
    const heartbeatTopic = "farm/1/field/1/master/MASTER-001/heartbeat";
    const payload = {
      firmwareVersion: "1.0.0",
      signalStrength: 31, // maximum signal
      batteryVoltage: 12.8,
      powerSource: "mainPower",
      tankLevel: 85,
      motorStatus: slaves[1][7] ? "on" : "off" // assume motor relay on Slave 1 Coil 7
    };
    client.publish(heartbeatTopic, JSON.stringify(payload));
    console.log(`[HEARTBEAT] Published status to backend.`);
  }, 15000);
});

interface ValveInput {
  valveId: string;
  modbusAddress: number;
  coilAddress: number;
}

client.on("message", (topic, message) => {
  try {
    const payload = JSON.parse(message.toString());
    const { commandUid, targetType, action } = payload;
    const valves = (payload.valves || []) as ValveInput[];

    console.log("\n==================================================================");
    console.log(`[MASTER] MQTT Command Received`);
    console.log(`Topic:       ${topic}`);
    console.log(`Command UID: ${commandUid}`);
    console.log(`Target:      ${targetType.toUpperCase()}`);
    console.log(`Action:      ${action.toUpperCase()}`);
    console.log(`Valves:      `, valves);
    console.log("==================================================================");

    // Motor actions are handled directly on the Master Board (or a dedicated motor relay)
    if (targetType === "motor") {
      console.log(`[MASTER] Onboard Motor Relay set to ${action === "open" ? "ON (Energized)" : "OFF (De-energized)"}`);
      
      // Toggle simulated motor status on Slave 1, Coil 7
      slaves[1][7] = action === "open" ? 1 : 0;

      // Send ACK back
      publishAck(commandUid, "acknowledged", []);
      return;
    }

    if (valves.length === 0) {
      console.log("[MASTER] Error: Valves list is empty!");
      publishAck(commandUid, "failed", []);
      return;
    }

    // Group target valves by Modbus Address (Unit ID)
    const groups: { [key: number]: ValveInput[] } = {};
    for (const v of valves) {
      const addr = Number(v.modbusAddress);
      if (!groups[addr]) groups[addr] = [];
      groups[addr].push(v);
    }

    const items: Array<{ valveId: string; status: string; currentValveStatus: string }> = [];

    // Process each Modbus Unit ID group
    for (const [unitIdStr, groupValves] of Object.entries(groups)) {
      const unitId = Number(unitIdStr);
      console.log(`\n[MASTER] Processing Modbus Group: Slave Unit ID ${unitId}`);

      let txBuffer: Buffer;
      let fc: number;

      // Group optimization logic:
      // If we have multiple coils to write, use Function Code 15 (0x0F) - Write Multiple Coils.
      // Otherwise, use Function Code 05 (0x05) - Write Single Coil.
      if (groupValves.length > 1) {
        fc = 15;
        // Compute range
        const coilAddresses = groupValves.map(gv => Number(gv.coilAddress));
        const minCoil = Math.min(...coilAddresses);
        const maxCoil = Math.max(...coilAddresses);
        const quantity = maxCoil - minCoil + 1;
        const byteCount = Math.ceil(quantity / 8);

        // Build output value byte
        const outputValues = [...slaves[unitId]]; // Copy current states
        for (const gv of groupValves) {
          outputValues[gv.coilAddress] = action === "open" ? 1 : 0;
        }

        // Pack bits into bytes starting from minCoil
        const valueBytes = Buffer.alloc(byteCount);
        for (let i = 0; i < quantity; i++) {
          const coilState = outputValues[minCoil + i];
          if (coilState === 1) {
            const byteIndex = Math.floor(i / 8);
            const bitIndex = i % 8;
            valueBytes[byteIndex] |= (1 << bitIndex);
          }
        }

        // Assemble frame: [UnitId (1), FC (1), StartAddr (2), Quantity (2), ByteCount (1), Values (byteCount)]
        const frameBody = Buffer.alloc(7 + byteCount);
        frameBody.writeUInt8(unitId, 0);
        frameBody.writeUInt8(fc, 1);
        frameBody.writeUInt16BE(minCoil, 2);
        frameBody.writeUInt16BE(quantity, 4);
        frameBody.writeUInt8(byteCount, 6);
        valueBytes.copy(frameBody, 7);

        const crc = calculateCRC(frameBody);
        txBuffer = Buffer.concat([frameBody, crc]);
      } else {
        fc = 5;
        const valve = groupValves[0];
        const coil = Number(valve.coilAddress);
        const value = action === "open" ? 0xFF00 : 0x0000;

        // Assemble frame: [UnitId (1), FC (1), CoilAddr (2), Value (2)]
        const frameBody = Buffer.alloc(6);
        frameBody.writeUInt8(unitId, 0);
        frameBody.writeUInt8(fc, 1);
        frameBody.writeUInt16BE(coil, 2);
        frameBody.writeUInt16BE(value, 4);

        const crc = calculateCRC(frameBody);
        txBuffer = Buffer.concat([frameBody, crc]);
      }

      console.log(`[MASTER] RS485 Tx -> [ ${formatHexFrame(txBuffer)} ]`);

      // --- SIMULATED SLAVE BOARD RECEPTION ---
      const rxBuffer = Buffer.from(txBuffer); // Simulated propagation over copper wire
      const rxUnitId = rxBuffer.readUInt8(0);
      const rxFc = rxBuffer.readUInt8(1);
      const rxCrc = rxBuffer.subarray(rxBuffer.length - 2);

      // Verify CRC
      const calculatedCrc = calculateCRC(rxBuffer.subarray(0, rxBuffer.length - 2));
      if (!rxCrc.equals(calculatedCrc)) {
        console.error(`[SLAVE ${rxUnitId}] Error: CRC Check failed!`);
        continue;
      }

      console.log(`[SLAVE ${rxUnitId}] RS485 Rx -> Checksum OK. Function Code: ${rxFc}`);

      // Perform coil state modification
      if (rxFc === 5) {
        const coilAddr = rxBuffer.readUInt16BE(2);
        const val = rxBuffer.readUInt16BE(4);
        slaves[rxUnitId][coilAddr] = val === 0xFF00 ? 1 : 0;

        const nameKey = `${rxUnitId}-${coilAddr}`;
        const vName = valveNames[nameKey] || `Coil #${coilAddr}`;
        console.log(`[SLAVE ${rxUnitId}] Operating Relay: ${vName} (Coil ${coilAddr}) set to ${val === 0xFF00 ? "ON" : "OFF"}`);
      } else if (rxFc === 15) {
        const startAddr = rxBuffer.readUInt16BE(2);
        const quantity = rxBuffer.readUInt16BE(4);
        const byteCount = rxBuffer.readUInt8(6);
        const valBytes = rxBuffer.subarray(7, 7 + byteCount);

        for (let i = 0; i < quantity; i++) {
          const byteIndex = Math.floor(i / 8);
          const bitIndex = i % 8;
          const bit = (valBytes[byteIndex] >> bitIndex) & 1;
          const coilAddr = startAddr + i;
          slaves[rxUnitId][coilAddr] = bit;

          const nameKey = `${rxUnitId}-${coilAddr}`;
          const vName = valveNames[nameKey] || `Coil #${coilAddr}`;
          console.log(`[SLAVE ${rxUnitId}] Operating Relay: ${vName} (Coil ${coilAddr}) set to ${bit ? "ON" : "OFF"}`);
        }
      }

      // Generate response frame
      let responseBody: Buffer;
      if (rxFc === 5) {
        // FC05 returns echo of request
        responseBody = rxBuffer.subarray(0, 6);
      } else {
        // FC15 returns: [UnitId, FC, StartAddr(2), Quantity(2)]
        responseBody = rxBuffer.subarray(0, 6);
      }
      const responseCrc = calculateCRC(responseBody);
      const responseFrame = Buffer.concat([responseBody, responseCrc]);

      console.log(`[SLAVE ${rxUnitId}] RS485 Tx (ACK) -> [ ${formatHexFrame(responseFrame)} ]`);
      console.log(`[MASTER] RS485 Rx (ACK) <- Verified CRC OK.`);

      // Update local master tracker for ACK response mapping
      for (const gv of groupValves) {
        items.push({
          valveId: gv.valveId,
          status: "acknowledged",
          currentValveStatus: action === "open" ? "open" : "closed"
        });
      }
    }

    // Publish compiled final response ACK to MQTT
    publishAck(commandUid, "acknowledged", items);

    // Also publish status dump to update dashboard statuses immediately
    publishStatusDump(items);

  } catch (err) {
    console.error("[DEVICE SIMULATOR] Error handling command message:", err);
  }
});

function publishAck(commandUid: string, status: string, items: any[]) {
  const ackTopic = "farm/1/field/1/master/MASTER-001/ack";
  const payload = {
    commandUid,
    status,
    items
  };
  client.publish(ackTopic, JSON.stringify(payload), { qos: 1 }, () => {
    console.log(`\n[MASTER] MQTT TX -> Published ACK to topic ${ackTopic}`);
  });
}

function publishStatusDump(items: any[]) {
  const statusTopic = "farm/1/field/1/master/MASTER-001/status";
  const payload = {
    valves: items.map(item => ({
      valveId: item.valveId,
      currentValveStatus: item.currentValveStatus
    }))
  };
  client.publish(statusTopic, JSON.stringify(payload), { qos: 1 }, () => {
    console.log(`[MASTER] MQTT TX -> Published status dump to topic ${statusTopic}`);
  });
}
