const { prisma } = require('../prisma/client');

const getValves = async (tenantId, zoneId, skip, take, filter) => {
    const params = {};
    if (skip) params.skip = Math.max(0, (parseInt(skip) - 1) * (parseInt(take) || 10));
    if (take) params.take = parseInt(take);

    const where = {};
    if (zoneId) {
        where.zoneId = zoneId;
    }
    if (tenantId) {
        where.zone = {
            field: { tenantId }
        };
    }
    if (filter) {
        where.name = { contains: filter, mode: 'insensitive' };
    }
    if (Object.keys(where).length) params.where = where;

    const count = await prisma.valve.count({ where: params.where || {} });
    const valves = await prisma.valve.findMany({
        ...params,
        where: params.where || {},
        orderBy: { name: 'asc' },
    });
    return { valves, count };
};

const getValveById = async (id, tenantId) => {
    const where = { id };
    if (tenantId) {
        where.zone = {
            field: { tenantId }
        };
    }
    const valve = await prisma.valve.findFirst({ where });
    if (!valve) throw new Error('Valve not found');
    return valve;
};

const createValve = async (data, tenantId) => {
    const { name, zoneId } = data;
    
    if (tenantId) {
        const zone = await prisma.zone.findFirst({
            where: {
                id: zoneId,
                field: { tenantId }
            }
        });
        if (!zone) throw new Error('Zone not found or access denied');
    }

    return prisma.valve.create({
        data: { name, zoneId }
    });
};

const updateValve = async (id, data, tenantId) => {
    const { name } = data;
    const where = { id };
    if (tenantId) {
        where.zone = {
            field: { tenantId }
        };
    }

    const existing = await prisma.valve.findFirst({ where });
    if (!existing) throw new Error('Valve not found');

    return prisma.valve.update({
        where: { id },
        data: { name }
    });
};

const deleteValve = async (id, tenantId) => {
    const where = { id };
    if (tenantId) {
        where.zone = {
            field: { tenantId }
        };
    }

    const existing = await prisma.valve.findFirst({ where });
    if (!existing) throw new Error('Valve not found');

    return prisma.valve.delete({ where: { id } });
};

module.exports = { getValves, getValveById, createValve, updateValve, deleteValve };
