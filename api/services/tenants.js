const { prisma } = require('../prisma/client');

const getTenants = async (skip, take, filter) => {
    const params = {};
    if (skip) params.skip = Math.max(0, (parseInt(skip) - 1) * (parseInt(take) || 10));
    if (take) params.take = parseInt(take);

    const where = {};
    if (filter) {
        where.OR = [
            { name: { contains: filter, mode: 'insensitive' } },
            { slug: { contains: filter, mode: 'insensitive' } },
        ];
    }
    if (Object.keys(where).length) params.where = where;

    const count = await prisma.tenant.count({ where: params.where || {} });
    const tenants = await prisma.tenant.findMany({
        ...params,
        orderBy: { createdAt: 'desc' },
    });
    return { tenants, count };
};

const getTenantById = async (id) => {
    const tenant = await prisma.tenant.findUnique({ where: { id } });
    if (!tenant) throw new Error('Tenant not found');
    return tenant;
};

const createTenant = async (data) => {
    const { name, slug, plan, useSubRoles } = data;
    return prisma.tenant.create({ 
        data: { 
            name, 
            slug, 
            plan: plan || 'starter',
            useSubRoles: useSubRoles ?? false
        } 
    });
};

const updateTenant = async (id, data) => {
    const { name, slug, plan, useSubRoles, isActive } = data;
    return prisma.tenant.update({ 
        where: { id }, 
        data: { 
            name, 
            slug, 
            plan, 
            useSubRoles,
            isActive
        } 
    });
};

const deleteTenant = async (id) => {
    return prisma.tenant.delete({ where: { id } });
};

module.exports = { getTenants, getTenantById, createTenant, updateTenant, deleteTenant };
