import mqtt from "mqtt";
import { env } from "../src/config/env";

const client = mqtt.connect(env.MQTT_URL);

client.on("connect", () => {
  client.publish(
    "farm/1/field/1/master/master-demo-001/heartbeat",
    JSON.stringify({
      firmwareVersion: "1.0.0",
      signalStrength: 80,
      batteryVoltage: 12.5,
      powerSource: "solar",
      tankLevel: 85,
      motorStatus: "on"
    }),
    { qos: 1 },
    () => {
      console.log("Mock heartbeat sent");
      client.end();
    }
  );
});
