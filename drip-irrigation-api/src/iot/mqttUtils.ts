import { Command, CommandItem, Valve } from "../../generated/prisma/client";
import { commandTopic } from "./topics";
import { publishMqtt } from "./mqttClient";
import { env } from "../config/env";

export interface CommandWithRelations extends Command {
  masterController: {
    deviceUid: string;
  };
  items: (CommandItem & {
    valve: Valve;
  })[];
}

/**
 * Utility to format and publish a database Command to the master controller via MQTT.
 */
export async function publishDeviceCommand(command: CommandWithRelations): Promise<void> {
  const topic = commandTopic(command.farmerId, command.fieldId, command.masterController.deviceUid);

  const payload = {
    commandUid: command.commandUid,
    targetType: command.targetType,
    targetId: command.targetId.toString(),
    action: command.action,
    zoneValveDelaySeconds: env.ZONE_VALVE_DELAY_SECONDS,
    items: command.items.map((item) => ({
      commandItemId: item.id.toString(),
      valveId: item.valveId.toString(),
      valveNumber: item.valve.valveNumber,
      action: item.action,
      sequenceNumber: item.sequenceNumber
    })),
    issuedAt: new Date().toISOString(),
    expiresAt: command.expiresAt?.toISOString()
  };

  await publishMqtt(topic, payload);
}
