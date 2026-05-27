const userService = require('../services/users');

const getUsers = async (req, res) => {
    try {
        const { skip, take, filter, role, customerId } = req.query;
        const excludeRoles = req.user.role === 'CUSTOMER_ADMIN' ? ['MACSOFT_ADMIN', 'MACSOFT_USER'] : [];
        const { users, count } = await userService.getUsers(skip, take, filter, role, excludeRoles, customerId);
        res.status(200).json({ users, totalPages: Math.ceil(count / (parseInt(take) || 10)), currentPage: parseInt(skip) || 1 });
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
};

const getUserById = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await userService.getUserById(id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.status(200).json(user);
    } catch (error) {
        console.error('Error fetching user by ID:', error);
        res.status(500).json({ error: 'Failed to fetch user' });
    }
};

const createUser = async (req, res) => {
    try {
        const data = req.body;
        const macsoftRoles = ['MACSOFT_ADMIN', 'MACSOFT_USER'];
        // Non-macsoft users always create users under their own customer
        if (!macsoftRoles.includes(req.user.role)) {
            data.customerId = req.user.customerId;
        }
        const newUser = await userService.createUser(data);
        res.status(201).json(newUser);
    } catch (error) {
        console.error('Error creating user:', error);
        res.status(500).json({ error: 'Failed to create user' });
    }
};

const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const data = req.body;
        const macsoftRoles = ['MACSOFT_ADMIN', 'MACSOFT_USER'];
        // Non-macsoft users cannot change customerId
        if (!macsoftRoles.includes(req.user.role)) {
            delete data.customerId;
        }
        const updatedUser = await userService.updateUser(id, data);
        res.status(200).json(updatedUser);
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
};

const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await userService.deleteUser(id);
        res.status(204).json(result);
    } catch (error) {
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