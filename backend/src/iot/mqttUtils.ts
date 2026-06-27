import { Command } from "../../generated/prisma/client";
import { commandTopic } from "./topics";
import { publishMqtt } from "./mqttClient";

export interface CommandWithRelations extends Command {
  masterController: {
    deviceUid: string;
  };
  items?: {
    valve: {
      id: bigint;
      coilAddress: number;
      slaveBoard: {
        deviceUid: string;
        modbusAddress: number;
      };
    };
  }[];
}

/**
 * Utility to format and publish a database Command to the master controller via MQTT.
 */
export async function publishDeviceCommand(command: CommandWithRelations): Promise<void> {
  const topic = commandTopic(command.farmerId, command.fieldId, command.masterController.deviceUid);

  const valves = command.items?.map(item => {
    return {
      valveId: item.valve.id.toString(),
      modbusAddress: item.valve.slaveBoard.modbusAddress,
      coilAddress: item.valve.coilAddress
    };
  }) ?? [];

  const payload = {
    commandUid: command.commandUid,
    fieldId: command.fieldId.toString(),
    targetType: command.targetType,
    targetId: command.targetId.toString(),
    action: command.action,
    valves
  };

  await publishMqtt(topic, payload);
}

