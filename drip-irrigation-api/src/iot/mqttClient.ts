import mqtt, { MqttClient } from "mqtt";
import { env } from "../config/env";
import { ackSubscriptionTopic, heartbeatSubscriptionTopic, statusSubscriptionTopic } from "./topics";
import { handleMqttMessage } from "./mqttHandlers";

let client: MqttClient | undefined;

export function getMqttClient() {
  if (!client) {
    client = mqtt.connect(env.MQTT_URL, {
      clientId: `${env.MQTT_CLIENT_ID}-${process.pid}`,
      username: env.MQTT_USERNAME || undefined,
      password: env.MQTT_PASSWORD || undefined,
      clean: true,
      reconnectPeriod: 3000
    });

    client.on("connect", () => {
      console.log("MQTT connected");
      client?.subscribe([ackSubscriptionTopic(), heartbeatSubscriptionTopic(), statusSubscriptionTopic()], (error) => {
        if (error) console.error("MQTT subscribe failed", error);
      });
    });

    client.on("message", (topic, payload) => {
      void handleMqttMessage(topic, payload.toString());
    });

    client.on("error", (error) => {
      console.error("MQTT error", error);
    });
  }

  return client;
}

export function publishMqtt(topic: string, payload: unknown) {
  const mqttClient = getMqttClient();

  return new Promise<void>((resolve, reject) => {
    mqttClient.publish(topic, JSON.stringify(payload), { qos: 1 }, (error) => {
      if (error) reject(error);
      else resolve();
    });
  });
}
