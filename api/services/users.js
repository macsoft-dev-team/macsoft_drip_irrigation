const {prisma} = require('../prisma/client');
const bcrypt = require("bcrypt");

const getUsers = async (skip, take, filter, role, excludeRoles = [], customerId) => {
    try {
        const params = {};
        if (skip) params.skip = (parseInt(skip) - 1) * parseInt(take) || 0;
        if (take) params.take = parseInt(take);

        const where = {};
        if (role) {
            where.role = role;
        } else if (excludeRoles.length) {
            where.role = { notIn: excludeRoles };
        }
        if (customerId) where.customerId = customerId;
        if (filter) {
            where.OR = [
                { name: { contains: filter, mode: 'insensitive' } },
                { email: { contains: filter, mode: 'insensitive' } },
                { phone: { contains: filter, mode: 'insensitive' } },
            ];
        }
        if (Object.keys(where).length) params.where = where;

        const count = await prisma.user.count({ where: params.where || {} });
        const users = await prisma.user.findMany({ ...params, include: { customer: { select: { id: true, name: true } } } });
        return { users, count };
    } catch (error) {
        console.error("Error fetching users:", error);
        throw error;
    }
};

const getUserById = async (id) => {
    try {
        const user = await prisma.user.findUnique({
            where: { id },
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
        const { name, email, phone, password, role, customerId } = data;
        const hashedPassword = await bcrypt.hash(password, 10);
        const newUser = await prisma.user.create({
            data: {
                name,
                email,
                phone,
                role: role || 'END_USER',
                password: hashedPassword,
                ...(customerId ? { customerId } : {}),
            },
            include: { customer: { select: { id: true, name: true } } },
        });
        return newUser;
    } catch (error) {
        console.error("Error creating user:", error);
        throw error;
    }
};

const updateUser = async (id, data) => {
    try {
        const { name, email, role, phone, password, customerId } = data;
        const hashedPassword = password
            ? await bcrypt.hash(password, 10)
            : undefined;
        const updatedUser = await prisma.user.update({
            where: { id },
            data: {
                name,
                email,
                role,
                phone,
                ...(customerId !== undefined ? { customerId } : {}),
                ...(hashedPassword !== undefined && { password: hashedPassword }),
            },
            include: { customer: { select: { id: true, name: true } } },
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