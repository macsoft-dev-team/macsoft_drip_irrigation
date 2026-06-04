const crypto = require("crypto");
const { prisma } =  require("../prisma/client"); 

function generateMqttDetails(imei) {
    const base = `device/${imei}`;

    const password = crypto
        .createHash("sha256")
        .update(imei + (process.env.MQTT_SECRET || "default_secret"))
        .digest("hex");

    return {
        mqttTelemetryTopic: `${base}/data`,
        mqttCommandTopic: `${base}/cmd`,
        mqttAckTopic: `${base}/cmd/res`,
        mqttClientId: `device_${imei}`,
        mqttUsername: `device_${imei}`,
        mqttPassword: password,
    };
} 

async function uploadDevices({ imeiList, tenantId, batchSize }) {
    const uniqueImeis = [...new Set(imeiList)];

    let created = 0;
    let skipped = 0;

    for (let i = 0; i < uniqueImeis.length; i += batchSize) {
        const batch = uniqueImeis.slice(i, i + batchSize);

        const existing = await prisma.device.findMany({
            where: {
                deviceUid: { in: batch },
            },
            select: { deviceUid: true },
        });

        const existingSet = new Set(existing.map((d) => d.deviceUid));

        const newImeis = batch.filter((i) => !existingSet.has(i));

        if (newImeis.length === 0) {
            skipped += batch.length;
            continue;
        }

        const data = newImeis.map((imei) => {
            const mqtt = generateMqttDetails(imei);
            return {
                deviceUid: imei,
                tenantId: tenantId,
                type: 'CONTROLLER',
                secretKey: mqtt.mqttPassword,
                mqttUsername: mqtt.mqttUsername,
                mqttPasswordHash: mqtt.mqttPassword,
                provisioningStatus: 'PENDING',
            };
        });
        
        const result = await prisma.device.createMany({
            data,
            skipDuplicates: true,
        });

        created += result.count;
        skipped += existing.length;
    }

    return {
        totalInput: imeiList.length,
        unique: uniqueImeis.length,
        created,
        skipped,
    };
}

function mapTelemetryRow(row) {
    if (!row) return row;
    const p = row.payload || {};
    return {
        ...row,
        time: row.time,
        // Voltages
        iv1: row.iv1 !== undefined ? row.iv1 : (p.IV1 != null ? Number(p.IV1) : null),
        iv2: row.iv2 !== undefined ? row.iv2 : (p.IV2 != null ? Number(p.IV2) : null),
        iv3: row.iv3 !== undefined ? row.iv3 : (p.IV3 != null ? Number(p.IV3) : null),
        // Currents
        ic1: row.ic1 !== undefined ? row.ic1 : (p.IC1 != null ? Number(p.IC1) : null),
        ic2: row.ic2 !== undefined ? row.ic2 : (p.IC2 != null ? Number(p.IC2) : null),
        ic3: row.ic3 !== undefined ? row.ic3 : (p.IC3 != null ? Number(p.IC3) : null),
        // Faults / Status
        flc: row.flc !== undefined ? row.flc : (p.FLT ?? p.FLC ?? null),
        sts: row.sts !== undefined ? row.sts : (p.STS ?? p.STM ?? null),
        // Other fields
        p1s: p.P1S ?? null,
        p2s: p.P2S ?? null,
        p3s: p.P3S ?? null,
        p4s: p.P4S ?? null,
        p5s: p.P5S ?? null,
        p1r: p.P1R ?? null,
        p2r: p.P2R ?? null,
        p3r: p.P3R ?? null,
        p4r: p.P4R ?? null,
        p5r: p.P5R ?? null,
        s1h: p.S1H ?? null,
        s2h: p.S2H ?? null,
        s3h: p.S3H ?? null,
        s4h: p.S4H ?? null,
        s5h: p.S5H ?? null,
        // Signal strength
        rsi: row.rsi !== undefined ? row.rsi : (row.signalStrength ?? p.signalStrength ?? p.signal ?? null),
    };
}

function mapDevice(d) {
    if (!d) return d;
    d.imeinumber = d.deviceUid;
    d.isActive = d.provisioningStatus === 'ACTIVE';
    d.config = d.config || null;
    d.state = d.state || null;
    if (d.telemetry) {
        d.telemetryLogs = d.telemetry.map(mapTelemetryRow);
    }
    return d;
}

const getDeviceById = async (id) => {
    const device = await prisma.device.findUnique({
        where: { id },
        include: {
            telemetry: { take: 1, orderBy: { time: 'desc' } },
            status: true,
            tenant: { select: { id: true, name: true } },
        },
    });
    return mapDevice(device);
};

const createDevice = async (data) => {
    try {
        const createdDevice = await prisma.device.create({ data });
        return mapDevice(createdDevice);
    } catch (error) {
        console.error('Error creating device:', error);
        throw error;
    }
};

const updateDevice = async (id, data) => {
    try {
        const { name, tenantId, ...rest } = data;
        const updatedDevice = await prisma.device.update({
            where: { id },
            data: {
                ...rest,
                name: name !== undefined ? (name || null) : undefined,
                tenantId: tenantId !== undefined ? (tenantId || null) : undefined,
            },
            include: {
                tenant: { select: { id: true, name: true } },
            },
        });
        return mapDevice(updatedDevice);
    } catch (error) {
        console.error('Error updating device:', error);
        throw error;
    }
};

const getDevices = async ({ skip = 0, take = 10, filter = '', tenantId }) => {
    try {
        const baseWhere = tenantId ? { tenantId } : {};

        const whereClause = filter
            ? {
                ...baseWhere,
                OR: [
                    { deviceUid: { contains: filter } },
                    { mqttUsername: { contains: filter } },
                ],
            }
            : baseWhere;

        const devices = await prisma.device.findMany({
            where: whereClause,
            skip: parseInt(skip),
            take: parseInt(take),
            orderBy: { id: 'desc' },
            include: {
                telemetry: {
                    take: 1,
                    orderBy: { time: 'desc' },
                },
                status: true,
                tenant: { select: { id: true, name: true } },
            },
        });

        devices.forEach(d => mapDevice(d));

        const totalCount = await prisma.device.count({ where: whereClause });

        return { devices, totalCount };
    } catch (error) {
        console.error('Error retrieving devices:', error);
        throw error;
    }
};

const getDeviceTelemetry = async ({ deviceId, from, to, take = 50, skip = 0 }) => {
    try {
        const where = { deviceId };
        if (from || to) {
            where.time = {};
            if (from) where.time.gte = new Date(from);
            if (to) where.time.lte = new Date(to);
        }
        const rows = await prisma.telemetry.findMany({
            where,
            orderBy: { time: 'desc' },
            take: parseInt(take),
            skip: parseInt(skip),
        });
        return rows.map(mapTelemetryRow);
    } catch (error) {
        console.error('Error retrieving telemetry:', error);
        throw error;
    }
};

// Map MQTT-key config payload → DeviceConfig DB field names
const n = (v) => (v != null ? Number(v) : undefined);
const mqttToDb = (cfg) => ({
    mxp: n(cfg.MXP),
    mnp: n(cfg.MNP),
    tfs: n(cfg.TFS),
    stp: n(cfg.STP),
    dfp: n(cfg.DFP),
    wut: n(cfg.WUT),
    lpc: n(cfg.LPC),
    msh: n(cfg.MSH),
    hvg: n(cfg.HVG),
    lvg: n(cfg.LVG),
    vcd: n(cfg.VCD),
    olc: n(cfg.OLC),
    ocd: n(cfg.OCD),
    drc: n(cfg.DRC),
    drd: n(cfg.DRD),
    swf: n(cfg.SWF),
    swt: n(cfg.SWT),
    slf: n(cfg.SLF),
    slt: n(cfg.SLT),
    pof: n(cfg.POF),
    pgn: n(cfg.PGN),
    ign: n(cfg.IGN),
    dgn: n(cfg.DGN),
});

const upsertDeviceConfig = async (deviceId, mqttCfg) => {
    const data = mqttToDb(mqttCfg);
    return { deviceId, ...data };
};

module.exports = {
    uploadDevices,
    getDeviceById,
    createDevice,
    updateDevice,
    upsertDeviceConfig,
    getDevices,
    getDeviceTelemetry,
};
