const userService = require('../services/users');

const getUsers = async (req, res) => {
    try {
        const { skip, take, filter, role, tenantId } = req.query;
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const targetTenantId = isSystemAdmin ? (tenantId || null) : req.user.tenantId;
        const excludeRoles = isSystemAdmin ? [] : ['SYSTEM_ADMIN'];

        const { users, count } = await userService.getUsers(skip, take, filter, role, excludeRoles, targetTenantId);
        res.status(200).json({
            users,
            totalPages: Math.ceil(count / (parseInt(take) || 10)),
            currentPage: parseInt(skip) || 1,
            totalCount: count
        });
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
};

const getUserById = async (req, res) => {
    try {
        const { id } = req.params;
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? null : req.user.tenantId;

        const user = await userService.getUserById(id, tenantId);
        res.status(200).json(user);
    } catch (error) {
        if (error.message === 'User not found') return res.status(404).json({ error: error.message });
        console.error('Error fetching user by ID:', error);
        res.status(500).json({ error: 'Failed to fetch user' });
    }
};

const createUser = async (req, res) => {
    try {
        const data = req.body;
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        if (!isSystemAdmin) {
            data.tenantId = req.user.tenantId;
        }
        if (!data.tenantId) {
            return res.status(400).json({ error: 'tenantId is required' });
        }
        const newUser = await userService.createUser(data);
        res.status(201).json(newUser);
    } catch (error) {
        if (error.message.includes('not found') || error.message.includes('denied') || error.message.includes('support') || error.message.includes('allowed')) {
            return res.status(400).json({ error: error.message });
        }
        console.error('Error creating user:', error);
        res.status(500).json({ error: 'Failed to create user' });
    }
};

const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const data = req.body;
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        if (!isSystemAdmin) {
            delete data.tenantId;
            if (data.role === 'SYSTEM_ADMIN') {
                delete data.role;
            }
        }
        const tenantId = isSystemAdmin ? null : req.user.tenantId;
        const updatedUser = await userService.updateUser(id, data, tenantId);
        res.status(200).json(updatedUser);
    } catch (error) {
        if (error.message === 'User not found') return res.status(404).json({ error: error.message });
        if (error.message.includes('denied') || error.message.includes('support') || error.message.includes('allowed')) {
            return res.status(400).json({ error: error.message });
        }
        console.error('Error updating user:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
};

const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        await userService.deleteUser(id);
        res.status(204).send();
    } catch (error) {
        if (error.message === 'User not found') return res.status(404).json({ error: error.message });
        console.error('Error deleting user:', error);
        res.status(500).json({ error: 'Failed to delete user' });
    }
};

module.exports = {
    getUsers,
    getUserById,
    createUser,
    updateUser,
    deleteUser,
};