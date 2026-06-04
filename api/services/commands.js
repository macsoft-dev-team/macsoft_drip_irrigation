// services/commands.js
const { prisma } = require('../prisma/client');
const mqttService = require('./mqtt');

async function sendCommand({ deviceId, payload }) {
    const device = await prisma.device.findUnique({
        where: { id: deviceId },
        select: { tenantId: true, deviceUid: true },
    });
    if (!device) throw new Error('Device not found');

    // Extract commandCode + value from single-key payload { CODE: value }
    const entries = Object.entries(payload);
    if (entries.length === 0) throw new Error('Payload must have at least one key');
    const [[commandCode, rawValue]] = entries;

    // Persist with PENDING status first
    const command = await prisma.command.create({
        data: { 
            deviceId, 
            tenantId: device.tenantId,
            commandType: commandCode,
            payload: payload,
            status: 'PENDING' 
        },
    });

    // Publish to device command topic
    const topic = `device/${device.deviceUid}/cmd`;
    const sent = mqttService.publish(topic, { ...payload, _cmdId: command.id ,deviceUid: device.deviceUid });

    // Update status to SENT or FAILED based on publish result
    const updated = await prisma.command.update({
        where: { id: command.id },
        data: {
            status:  sent ? 'SENT' : 'FAILED',
            sentAt:  sent ? new Date() : null,
        },
    });

    return updated;
}

async function getCommands({ deviceId, take = 20, skip = 0 }) {
    return prisma.command.findMany({
        where: { deviceId },
        orderBy: { createdAt: 'desc' },
        take: parseInt(take),
        skip: parseInt(skip),
    });
}

module.exports = { sendCommand, getCommands };
