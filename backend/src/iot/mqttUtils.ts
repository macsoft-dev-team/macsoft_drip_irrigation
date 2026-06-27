import { Command } from "../../generated/prisma/client";
import { commandTopic } from "./topics";
import { publishMqtt } from "./mqttClient";

export interface CommandWithRelations extends Command {
  masterController: {
    deviceUid: string;
  };
}

/**
 * Utility to format and publish a database Command to the master controller via MQTT.
 */
export async function publishDeviceCommand(command: CommandWithRelations): Promise<void> {
  const topic = commandTopic(command.farmerId, command.fieldId, command.masterController.deviceUid);

  const payload = {
    commandUid: command.commandUid,
    fieldId: command.fieldId.toString(),
    targetType: command.targetType,
    targetId: command.targetId.toString(),
    action: command.action
  };

  await publishMqtt(topic, payload);
}

