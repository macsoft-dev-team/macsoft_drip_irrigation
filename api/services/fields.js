const { prisma } = require('../prisma/client');

const getFields = async (customerId, skip, take, filter) => {
    const params = {};
    if (skip) params.skip = (parseInt(skip) - 1) * parseInt(take) || 0;
    if (take) params.take = parseInt(take);

    const where = {};
    if (customerId) where.customerId = customerId;
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

const getFieldById = async (id, customerId) => {
    const where = { id };
    if (customerId) where.customerId = customerId;
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
    const { name, customerId } = data;
    return prisma.field.create({
        data: { name, customerId },
        include: {
            zones: {
                include: {
                    valves: true
                }
            }
        }
    });
};

const updateField = async (id, data, customerId) => {
    const { name } = data;
    const where = { id };
    if (customerId) where.customerId = customerId;
    
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

const deleteField = async (id, customerId) => {
    const where = { id };
    if (customerId) where.customerId = customerId;

    const existing = await prisma.field.findFirst({ where });
    if (!existing) throw new Error('Field not found');

    return prisma.field.delete({ where: { id } });
};

module.exports = { getFields, getFieldById, createField, updateField, deleteField };
