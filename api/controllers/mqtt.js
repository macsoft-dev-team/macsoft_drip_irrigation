const { prisma } = require('../prisma/client');
const bcrypt = require('bcrypt');
const redis = require('../services/redis');

const SUPERUSER_USERNAME = process.env.MQTT_USERNAME;
const SUPERUSER_PASSWORD = process.env.MQTT_PASSWORD;

const CACHE_TTL = 600; // 10 minutes

exports.authenticate = async (req, res) => {
    const { username, password, clientid } = req.body;

    if (!username || !password || !clientid) {
        return res.json({ result: 'deny' });
    }

    // Superuser bypass
    if (username === SUPERUSER_USERNAME && password === SUPERUSER_PASSWORD) {
        return res.json({ result: 'allow', is_superuser: true });
    }

    try {
        const cacheKey = `mqtt:auth:${username}:${clientid}`;

        // Safe Redis read (with timeout)
        const cached = await safeRedisGet(cacheKey);

        if (cached) {
            return res.json(JSON.parse(cached));
        }

        // DB lookup
        const device = await prisma.device.findUnique({
            where: { mqttUsername: username },
            select: {
                mqttPassword: true,
                mqttClientId: true,
                mqttDataTopic: true,
                mqttCmdTopic: true,
                mqttCmdResponseTopic: true,
                imeinumber: true,
                isActive: true,
            },
        });

        if (!device || !device.isActive) {
            return res.json({ result: 'deny' });
        }

        // Strict client check
        if (device.mqttClientId !== clientid) {
            return res.json({ result: 'deny' });
        }

        // Password check (only on miss)
        const match = await bcrypt.compare(password, device.mqttPassword);
        if (!match) {
            return res.json({ result: 'deny' });
        }

        const response = buildResponse(device);

        // Cache AFTER full validation
        await safeRedisSet(cacheKey, JSON.stringify(response), CACHE_TTL);

        return res.json(response);

    } catch (error) {
        console.error('MQTT auth error:', error);
        return res.json({ result: 'ignore' });
    }
};

// ================= SAFE REDIS =================

async function safeRedisGet(key) {
    try {
        return await Promise.race([
            redis.get(key),
            new Promise((resolve) => setTimeout(() => resolve(null), 50))
        ]);
    } catch {
        return null;
    }
}

async function safeRedisSet(key, value, ttl) {
    try {
        await redis.set(key, value, 'EX', ttl);
    } catch {
        // ignore
    }
}

// ================= ACL BUILDER =================

function buildResponse(device) {
    const acl = [];

    const deviceId = device.imeinumber;

    // Publish own data
    if (device.mqttDataTopic) {
        acl.push({
            permission: 'allow',
            action: 'publish',
            topic: device.mqttDataTopic,
        });

        // optional debug
        acl.push({
            permission: 'allow',
            action: 'subscribe',
            topic: device.mqttDataTopic,
        });
    }

    // Receive commands
    if (device.mqttCmdTopic) {
        acl.push({
            permission: 'allow',
            action: 'subscribe',
            topic: device.mqttCmdTopic,
        });
    }

    // Send responses
    if (device.mqttCmdResponseTopic) {
        acl.push({
            permission: 'allow',
            action: 'publish',
            topic: device.mqttCmdResponseTopic,
        });
    }

    // Cross-device communication (controlled)
    acl.push({
        permission: 'allow',
        action: 'publish',
        topic: `device/+/tank`,
    });

    // Receive messages sent to this device
    acl.push({
        permission: 'allow',
        action: 'subscribe',
        topic: `device/${deviceId}/+`,
    });

    // Final deny
    acl.push({
        permission: 'deny',
        action: 'all',
        topic: '#',
    });

    return {
        result: 'allow',
        is_superuser: false,
        acl,
    };
}