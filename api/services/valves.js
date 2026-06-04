const { prisma } = require('../prisma/client');

const getValves = async (customerId, zoneId, skip, take, filter) => {
    const params = {};
    if (skip) params.skip = (parseInt(skip) - 1) * parseInt(take) || 0;
    if (take) params.take = parseInt(take);

    const where = {};
    if (zoneId) {
        where.zoneId = zoneId;
    }
    if (customerId) {
        where.zone = {
            field: { customerId }
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

const getValveById = async (id, customerId) => {
    const where = { id };
    if (customerId) {
        where.zone = {
            field: { customerId }
        };
    }
    const valve = await prisma.valve.findFirst({ where });
    if (!valve) throw new Error('Valve not found');
    return valve;
};

const createValve = async (data, customerId) => {
    const { name, zoneId } = data;
    
    if (customerId) {
        const zone = await prisma.zone.findFirst({
            where: {
                id: zoneId,
                field: { customerId }
            }
        });
        if (!zone) throw new Error('Zone not found or access denied');
    }

    return prisma.valve.create({
        data: { name, zoneId }
    });
};

const updateValve = async (id, data, customerId) => {
    const { name } = data;
    const where = { id };
    if (customerId) {
        where.zone = {
            field: { customerId }
        };
    }

    const existing = await prisma.valve.findFirst({ where });
    if (!existing) throw new Error('Valve not found');

    return prisma.valve.update({
        where: { id },
        data: { name }
    });
};

const deleteValve = async (id, customerId) => {
    const where = { id };
    if (customerId) {
        where.zone = {
            field: { customerId }
        };
    }

    const existing = await prisma.valve.findFirst({ where });
    if (!existing) throw new Error('Valve not found');

    return prisma.valve.delete({ where: { id } });
};

module.exports = { getValves, getValveById, createValve, updateValve, deleteValve };
