const { prisma } = require('../prisma/client');

const getZones = async (tenantId, fieldId, skip, take, filter) => {
    const params = {};
    if (skip) params.skip = Math.max(0, (parseInt(skip) - 1) * (parseInt(take) || 10));
    if (take) params.take = parseInt(take);

    const where = {};
    if (fieldId) {
        where.fieldId = fieldId;
    }
    if (tenantId) {
        where.field = { tenantId };
    }
    if (filter) {
        where.name = { contains: filter, mode: 'insensitive' };
    }
    if (Object.keys(where).length) params.where = where;

    const count = await prisma.zone.count({ where: params.where || {} });
    const zones = await prisma.zone.findMany({
        ...params,
        where: params.where || {},
        include: {
            valves: true
        },
        orderBy: { name: 'asc' },
    });
    return { zones, count };
};

const getZoneById = async (id, tenantId) => {
    const where = { id };
    if (tenantId) {
        where.field = { tenantId };
    }
    const zone = await prisma.zone.findFirst({
        where,
        include: {
            valves: true
        }
    });
    if (!zone) throw new Error('Zone not found');
    return zone;
};

const createZone = async (data, tenantId) => {
    const { name, fieldId } = data;
    
    if (tenantId) {
        const field = await prisma.field.findFirst({
            where: { id: fieldId, tenantId }
        });
        if (!field) throw new Error('Field not found or access denied');
    }

    return prisma.zone.create({
        data: { name, fieldId },
        include: {
            valves: true
        }
    });
};

const updateZone = async (id, data, tenantId) => {
    const { name } = data;
    const where = { id };
    if (tenantId) {
        where.field = { tenantId };
    }

    const existing = await prisma.zone.findFirst({ where });
    if (!existing) throw new Error('Zone not found');

    return prisma.zone.update({
        where: { id },
        data: { name },
        include: {
            valves: true
        }
    });
};

const deleteZone = async (id, tenantId) => {
    const where = { id };
    if (tenantId) {
        where.field = { tenantId };
    }

    const existing = await prisma.zone.findFirst({ where });
    if (!existing) throw new Error('Zone not found');

    return prisma.zone.delete({ where: { id } });
};

module.exports = { getZones, getZoneById, createZone, updateZone, deleteZone };
