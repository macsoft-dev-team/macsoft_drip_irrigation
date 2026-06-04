const bcrypt = require("bcrypt");
const devicesService = require("../services/devices");
const commandsService = require("../services/commands");

const SYSTEM_ROLES = ['SYSTEM_ADMIN'];

// Validates a 15-digit IMEI using the Luhn algorithm
const isValidImei = (imei) => {
    const str = String(imei).trim();
    if (!/^\d{15}$/.test(str)) return false;
    let sum = 0;
    for (let i = 0; i < 15; i++) {
        let digit = parseInt(str[i]);
        if (i % 2 === 1) {
            digit *= 2;
            if (digit > 9) digit -= 9;
        }
        sum += digit;
    }
    return sum % 10 === 0;
};

const uploadDevices = async (req, res) => {
    try {
        let raw = [];

        if (req.body?.imeis) {
            raw = JSON.parse(req.body.imeis);
        }

        if (!Array.isArray(raw) || raw.length === 0) {
            return res.status(400).json({
                error: "No IMEI data provided",
            });
        }

        // Normalize → ONLY STRINGS
        const imeiList = raw.map((item) =>
            typeof item === "string" ? item : item.imeinumber
        );

        // Validate
        const invalid = [];
        const valid = [];

        imeiList.forEach((imei, index) => {
            const clean = String(imei || "").trim();

            if (!clean || !/^\d{15}$/.test(clean)) {
                invalid.push({
                    row: index + 1,
                    imei: clean || "(empty)",
                });
            } else {
                valid.push(clean);
            }
        });

        if (invalid.length > 0) {
            return res.status(400).json({
                error: "Invalid IMEIs",
                invalid,
            });
        }

        const batchSize = Math.min(
            Math.max(parseInt(req.query.batchSize) || 100, 1),
            1000
        );

        const tenantId = req.user.tenantId;

        const result = await devicesService.uploadDevices({
            imeiList: valid,
            tenantId,
            batchSize,
        });

        return res.status(200).json({
            success: true,
            data: result,
        });
    } catch (err) {
        console.error(err);

        return res.status(500).json({
            error: "Internal server error",
            message: err.message,
        });
    }
};

const createDevice = async (req, res) => {
    try {
        const { imeinumber, code, pumpModel, latitude, longitude,
                mqttClientId, mqttUsername, mqttPassword,
                mqttTelemetryTopic, mqttCommandTopic, mqttAckTopic } = req.body;

        if (!imeinumber) {
            return res.status(400).json({ error: "IMEI number is required" });
        }

        if (!isValidImei(imeinumber)) {
            return res.status(400).json({ error: "Invalid IMEI number" });
        }

        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? (req.body.tenantId || req.user.tenantId) : req.user.tenantId;

        const deviceData = {
            deviceUid: imeinumber,
            tenantId,
            type: 'CONTROLLER',
            secretKey: mqttPassword || imeinumber,
            mqttUsername: mqttUsername || `user_${imeinumber}`,
            mqttPasswordHash: mqttPassword || bcrypt.hashSync(imeinumber, 10),
            provisioningStatus: 'ACTIVE',
        };

        const createdDevice = await devicesService.createDevice(deviceData);

        if (!createdDevice) {
            return res.status(500).json({ error: "Failed to create device" });
        }
     
        return res.status(201).json({
            success: true,
            message: "Device created successfully",
            data: createdDevice,
        });
    } catch (error) {
        console.error("Error in createDevice controller:", error);

        // Prisma unique constraint violation (P2002)
        if (error.code === 'P2002') {
            const field = error.meta?.target?.join(', ') || 'field';
            return res.status(400).json({
                error: `A device with this ${field} already exists.`,
            });
        }
        // Prisma foreign key constraint violation (P2003)
        if (error.code === 'P2003') {
            return res.status(400).json({
                error: 'Invalid tenant account. Please contact your administrator.',
            });
        }

        return res.status(500).json({
            error: "Internal server error",
            message: error.message,
        });
    }
};

const updateDevice = async (req, res) => {
    try {
        const deviceId = req.params.id;
        const updateData = { ...req.body };

        const isSystemAdmin = req.user?.role === 'SYSTEM_ADMIN';
        if (!isSystemAdmin) {
            delete updateData.tenantId;
            delete updateData.customerId;
        }

        if (updateData.imeinumber) {
            if (!isValidImei(updateData.imeinumber)) {
                return res.status(400).json({ error: "Invalid IMEI number" });
            }
            updateData.deviceUid = updateData.imeinumber;
            delete updateData.imeinumber;
        }
        if (updateData.customerId) {
            updateData.tenantId = updateData.customerId;
            delete updateData.customerId;
        }

        const updatedDevice = await devicesService.updateDevice(deviceId, updateData);

        if (!updatedDevice) {
            return res.status(404).json({ error: "Device not found" });
        }

        return res.status(200).json({
            success: true,
            message: "Device updated successfully",
            data: updatedDevice,
        });
    } catch (error) {
        console.error("Error in updateDevice controller:", error);
        return res.status(500).json({
            error: "Internal server error",
            message: error.message,
        });
    }
};

const getDeviceById = async (req, res) => {
    try {
        const { id } = req.params;
        const device = await devicesService.getDeviceById(id);
        if (!device) return res.status(404).json({ error: 'Device not found' });
        return res.status(200).json({ success: true, data: device });
    } catch (error) {
        console.error('Error in getDeviceById controller:', error);
        return res.status(500).json({ error: 'Internal server error', message: error.message });
    }
};

const getDevices = async (req, res) => {
    try {
        const { skip, take, filter } = req.query;
        const isSystemAdmin = req.user?.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? (req.query.tenantId || undefined) : req.user.tenantId;
        const devices = await devicesService.getDevices({ skip, take, filter, tenantId });
        return res.status(200).json({
            success: true,
            message: "Devices retrieved successfully",
            data: devices,
        });
    } catch (error) {
        console.error("Error in getDevices controller:", error);
        return res.status(500).json({
            error: "Internal server error",
            message: error.message,
        });
    }
};

const getDeviceTelemetry = async (req, res) => {
    try {
        const { id } = req.params;
        const { from, to, take, skip } = req.query;
        const rows = await devicesService.getDeviceTelemetry({ deviceId: id, from, to, take, skip });
        return res.status(200).json({ success: true, data: rows });
    } catch (error) {
        console.error('Error in getDeviceTelemetry controller:', error);
        return res.status(500).json({ error: 'Internal server error', message: error.message });
    }
};

module.exports = {
    uploadDevices,
    createDevice,
    getDeviceById,
    updateDevice,
    getDevices,
    getDeviceTelemetry,
    sendCommand,
    getCommands,
    saveDeviceConfig,
};

async function sendCommand(req, res) {
    try {
        const { id } = req.params;
        const payload = req.body;
        if (!payload || typeof payload !== 'object' || Object.keys(payload).length === 0) {
            return res.status(400).json({ error: 'Command payload is required' });
        }
        const command = await commandsService.sendCommand({ deviceId: id, payload });
        return res.status(201).json({ success: true, data: command });
    } catch (error) {
        console.error('Error in sendCommand controller:', error);
        return res.status(500).json({ error: 'Internal server error', message: error.message });
    }
}

async function getCommands(req, res) {
    try {
        const { id } = req.params;
        const { take, skip } = req.query;
        const commands = await commandsService.getCommands({ deviceId: id, take, skip });
        return res.status(200).json({ success: true, data: commands });
    } catch (error) {
        console.error('Error in getCommands controller:', error);
        return res.status(500).json({ error: 'Internal server error', message: error.message });
    }
}

async function saveDeviceConfig(req, res) {
    try {
        const { id } = req.params;
        const payload = req.body;

        if (!payload || typeof payload !== 'object' || Object.keys(payload).length === 0) {
            return res.status(400).json({ error: 'Config payload is required' });
        }

        const config = await devicesService.upsertDeviceConfig(id, payload);
        return res.status(200).json({ success: true, data: config });
    } catch (error) {
        console.error('Error in saveDeviceConfig controller:', error);
        return res.status(500).json({ error: 'Internal server error', message: error.message });
    }
}
