import mqtt from "mqtt";
import { env } from "../src/config/env";

const commandUid = process.argv[2];

if (!commandUid) {
  console.error("Usage: npm run test:mqtt:ack -- <commandUid>");
  process.exit(1);
}

const client = mqtt.connect(env.MQTT_URL);

client.on("connect", () => {
  client.publish(
    "farm/1/field/1/master/master-demo-001/ack",
    JSON.stringify({
      commandUid,
      status: "acknowledged",
      items: [
        {
          valveId: "1",
          status: "acknowledged",
          currentValveStatus: "open"
        }
      ]
    }),
    { qos: 1 },
    () => {
      console.log("Mock ACK sent");
      client.end();
    }
  );
});
