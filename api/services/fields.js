const { prisma } = require('../prisma/client');

const getFields = async (tenantId, skip, take, filter) => {
    const params = {};
    if (skip) params.skip = Math.max(0, (parseInt(skip) - 1) * (parseInt(take) || 10));
    if (take) params.take = parseInt(take);

    const where = {};
    if (tenantId) where.tenantId = tenantId;
    if (filter) {
        where.name = { contains: filter, mode: 'insensitive' };
    }
    if (Object.keys(where).length) params.where = where;

    const count = await prisma.field.count({ where: params.where || {} });
    const fields = await prisma.field.findMany({
        ...params,
        where: params.where || {},
        include: {
            zones: {
                include: {
                    valves: true
                }
            }
        },
        orderBy: { name: 'asc' },
    });
    return { fields, count };
};

const getFieldById = async (id, tenantId) => {
    const where = { id };
    if (tenantId) where.tenantId = tenantId;
    const field = await prisma.field.findFirst({
        where,
        include: {
            zones: {
                include: {
                    valves: true
                }
            }
        }
    });
    if (!field) throw new Error('Field not found');
    return field;
};

const createField = async (data) => {
    const { name, tenantId } = data;
    return prisma.field.create({
        data: { name, tenantId },
        include: {
            zones: {
                include: {
                    valves: true
                }
            }
        }
    });
};

const updateField = async (id, data, tenantId) => {
    const { name } = data;
    const where = { id };
    if (tenantId) where.tenantId = tenantId;
    
    const existing = await prisma.field.findFirst({ where });
    if (!existing) throw new Error('Field not found');

    return prisma.field.update({
        where: { id },
        data: { name },
        include: {
            zones: {
                include: {
                    valves: true
                }
            }
        }
    });
};

const deleteField = async (id, tenantId) => {
    const where = { id };
    if (tenantId) where.tenantId = tenantId;

    const existing = await prisma.field.findFirst({ where });
    if (!existing) throw new Error('Field not found');

    return prisma.field.delete({ where: { id } });
};

module.exports = { getFields, getFieldById, createField, updateField, deleteField };
