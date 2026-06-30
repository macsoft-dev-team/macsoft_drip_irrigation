export function commandTopic(farmerId: bigint, fieldId: bigint, deviceUid: string) {
  return `farm/${farmerId.toString()}/field/${fieldId.toString()}/master/${deviceUid}/command`;
}

export function configTopic(farmerId: bigint, fieldId: bigint, deviceUid: string) {
  return `farm/${farmerId.toString()}/field/${fieldId.toString()}/master/${deviceUid}/config`;
}

export function ackSubscriptionTopic() {
  return "farm/+/field/+/master/+/ack";
}

export function heartbeatSubscriptionTopic() {
  return "farm/+/field/+/master/+/heartbeat";
}

export function statusSubscriptionTopic() {
  return "farm/+/field/+/master/+/status";
}
