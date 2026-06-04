const {prisma} = require('../prisma/client');
const bcrypt = require("bcrypt");

const getUsers = async (skip, take, filter, role, excludeRoles = [], tenantId) => {
    try {
        const params = {};
        if (skip) params.skip = Math.max(0, (parseInt(skip) - 1) * (parseInt(take) || 10));
        if (take) params.take = parseInt(take);

        const where = {};
        if (role) {
            where.role = role;
        } else if (excludeRoles.length) {
            where.role = { notIn: excludeRoles };
        }
        if (tenantId) where.tenantId = tenantId;
        if (filter) {
            where.OR = [
                { name: { contains: filter, mode: 'insensitive' } },
                { email: { contains: filter, mode: 'insensitive' } },
            ];
        }
        if (Object.keys(where).length) params.where = where;

        const count = await prisma.user.count({ where: params.where || {} });
        const users = await prisma.user.findMany({
            ...params,
            where: params.where || {},
            include: { tenant: { select: { id: true, name: true } } }
        });
        return { users, count };
    } catch (error) {
        console.error("Error fetching users:", error);
        throw error;
    }
};

const getUserById = async (id, tenantId) => {
    try {
        const where = { id };
        if (tenantId) where.tenantId = tenantId;
        const user = await prisma.user.findFirst({
            where,
        });
        if (!user) {
            throw new Error("User not found");
        }
        return user;
    } catch (error) {
        console.error("Error fetching user by ID:", error);
        throw error;
    }
};

const createUser = async (data) => {
    try {
        const { name, email, password, role, tenantId } = data;

        if (tenantId) {
            const tenant = await prisma.tenant.findUnique({ where: { id: tenantId } });
            if (!tenant) throw new Error('Tenant not found');
            
            const resolvedRole = role || 'CUSTOMER';
            if (!tenant.useSubRoles && (resolvedRole === 'CUSTOMER_ADMIN' || resolvedRole === 'CUSTOMER_USER')) {
                throw new Error('Tenant does not support sub-roles. Only CUSTOMER role is allowed.');
            }
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const newUser = await prisma.user.create({
            data: {
                name,
                email,
                role: role || 'CUSTOMER',
                passwordHash: hashedPassword,
                tenantId,
            },
            include: { tenant: { select: { id: true, name: true } } },
        });
        return newUser;
    } catch (error) {
        console.error("Error creating user:", error);
        throw error;
    }
};

const updateUser = async (id, data, tenantId) => {
    try {
        const { name, email, role, password, tenantId: newTenantId } = data;

        const where = { id };
        if (tenantId) where.tenantId = tenantId;
        const existing = await prisma.user.findFirst({ where });
        if (!existing) throw new Error('User not found');

        const targetTenantId = newTenantId || existing.tenantId;
        const targetRole = role || existing.role;

        const tenant = await prisma.tenant.findUnique({ where: { id: targetTenantId } });
        if (!tenant) throw new Error('Tenant not found');
        if (!tenant.useSubRoles && (targetRole === 'CUSTOMER_ADMIN' || targetRole === 'CUSTOMER_USER')) {
            throw new Error('Tenant does not support sub-roles. Only CUSTOMER role is allowed.');
        }

        const hashedPassword = password
            ? await bcrypt.hash(password, 10)
            : undefined;

        const updatedUser = await prisma.user.update({
            where: { id },
            data: {
                name,
                email,
                role,
                ...(newTenantId !== undefined && { tenantId: newTenantId }),
                ...(hashedPassword !== undefined && { passwordHash: hashedPassword }),
            },
            include: { tenant: { select: { id: true, name: true } } },
        });
        return updatedUser;
    } catch (error) {
        console.error("Error updating user:", error);
        throw error;
    }
};

const deleteUser = async (id) => {
    try {
        await prisma.user.delete({
            where: { id },
        });
    } catch (error) {
        console.error("Error deleting user:", error);
        throw error;
    }
};

module.exports = {
    getUsers,
    getUserById,
    createUser,
    updateUser,
    deleteUser,
};