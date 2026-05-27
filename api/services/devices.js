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

async function uploadDevices({ imeiList, customerId, batchSize }) {
    const uniqueImeis = [...new Set(imeiList)];

    let created = 0;
    let skipped = 0;

    for (let i = 0; i < uniqueImeis.length; i += batchSize) {
        const batch = uniqueImeis.slice(i, i + batchSize);

        const existing = await prisma.device.findMany({
            where: {
                imeinumber: { in: batch },
            },
            select: { imeinumber: true },
        });

        const existingSet = new Set(existing.map((d) => d.imeinumber));

        const newImeis = batch.filter((i) => !existingSet.has(i));

        if (newImeis.length === 0) {
            skipped += batch.length;
            continue;
        }

        const data = newImeis.map((imei) => ({
            imeinumber: imei,
            code: imei.slice(-6),
            pumpModel: 'MODEL_1P1',
            customerId: customerId || undefined,
            ...generateMqttDetails(imei),
        }));
        
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

const getDeviceById = async (id) => {
    return prisma.device.findUnique({
        where: { id },
        include: {
            telemetry: { take: 1, orderBy: { timestamp: 'desc' } },
            config: true,
            state: true,
            customer: { select: { id: true, name: true } },
        },
    });
};

const createDevice = async (data) => {
    try {
        const createdDevice = await prisma.device.create({ data });
        return createdDevice;
    } catch (error) {
        console.error('Error creating device:', error);
        throw error;
    }
};

const updateDevice = async (id, data) => {
    try {
        const { name, customerId, ...rest } = data;
        const updatedDevice = await prisma.device.update({
            where: { id },
            data: {
                ...rest,
                name: name !== undefined ? (name || null) : undefined,
                customerId: customerId !== undefined ? (customerId || null) : undefined,
            },
            include: {
                customer: { select: { id: true, name: true } },
            },
        });
        return updatedDevice;
    } catch (error) {
        console.error('Error updating device:', error);
        throw error;
    }
};

const getDevices = async ({ skip = 0, take = 10, filter = '', customerId }) => {
    try {
        const baseWhere = customerId ? { customerId } : {};

        const whereClause = filter
            ? {
                ...baseWhere,
                OR: [
                    { imeinumber: { contains: filter } },
                    { mqttUsername: { contains: filter } },
                    { mqttClientId: { contains: filter } },
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
                    orderBy: { timestamp: 'desc' },
                },
                config: true,
                customer: { select: { id: true, name: true } },
            },
        });

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
            where.timestamp = {};
            if (from) where.timestamp.gte = new Date(from);
            if (to) where.timestamp.lte = new Date(to);
        }
        const rows = await prisma.deviceTelemetry.findMany({
            where,
            orderBy: { timestamp: 'desc' },
            take: parseInt(take),
            skip: parseInt(skip),
        });
        return rows;
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
    // Remove undefined keys so Prisma doesn't null-out fields not in payload
    Object.keys(data).forEach((k) => data[k] === undefined && delete data[k]);

    return prisma.deviceConfig.upsert({
        where:  { deviceId },
        update: data,
        create: { deviceId, ...data },
    });
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
