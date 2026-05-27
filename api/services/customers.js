const { prisma } = require('../prisma/client');

const getCustomers = async (skip, take, filter) => {
    const params = {};
    if (skip) params.skip = (parseInt(skip) - 1) * parseInt(take) || 0;
    if (take) params.take = parseInt(take);

    const where = {};
    if (filter) {
        where.OR = [
            { name: { contains: filter, mode: 'insensitive' } },
            { email: { contains: filter, mode: 'insensitive' } },
        ];
    }
    if (Object.keys(where).length) params.where = where;

    const count = await prisma.customer.count({ where: params.where || {} });
    const customers = await prisma.customer.findMany({
        ...params,
        orderBy: { createdAt: 'desc' },
    });
    return { customers, count };
};

const getCustomerById = async (id) => {
    const customer = await prisma.customer.findUnique({ where: { id } });
    if (!customer) throw new Error('Customer not found');
    return customer;
};

const createCustomer = async (data) => {
    const { name, email } = data;
    return prisma.customer.create({ data: { name, email } });
};

const updateCustomer = async (id, data) => {
    const { name, email } = data;
    return prisma.customer.update({ where: { id }, data: { name, email } });
};

const deleteCustomer = async (id) => {
    return prisma.customer.delete({ where: { id } });
};

module.exports = { getCustomers, getCustomerById, createCustomer, updateCustomer, deleteCustomer };
