const fieldService = require('../services/fields');

const getFields = async (req, res) => {
    try {
        const { skip, take, filter } = req.query;
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? (req.query.customerId || null) : req.user.customerId;

        const { fields, count } = await fieldService.getFields(customerId, skip, take, filter);
        res.status(200).json({
            fields,
            totalPages: Math.ceil(count / (parseInt(take) || 100)),
            currentPage: parseInt(req.query.skip) || 1,
            totalCount: count
        });
    } catch (error) {
        console.error('Error fetching fields:', error);
        res.status(500).json({ error: 'Failed to fetch fields' });
    }
};

const getFieldById = async (req, res) => {
    try {
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? null : req.user.customerId;
        const field = await fieldService.getFieldById(req.params.id, customerId);
        res.status(200).json(field);
    } catch (error) {
        if (error.message === 'Field not found') return res.status(404).json({ error: error.message });
        console.error('Error fetching field:', error);
        res.status(500).json({ error: 'Failed to fetch field' });
    }
};

const createField = async (req, res) => {
    try {
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? req.body.customerId : req.user.customerId;
        if (!customerId) {
            return res.status(400).json({ error: 'CustomerId is required' });
        }
        const field = await fieldService.createField({
            name: req.body.name,
            customerId
        });
        res.status(201).json(field);
    } catch (error) {
        console.error('Error creating field:', error);
        res.status(500).json({ error: 'Failed to create field' });
    }
};

const updateField = async (req, res) => {
    try {
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? null : req.user.customerId;
        const field = await fieldService.updateField(req.params.id, req.body, customerId);
        res.status(200).json(field);
    } catch (error) {
        if (error.message === 'Field not found') return res.status(404).json({ error: error.message });
        console.error('Error updating field:', error);
        res.status(500).json({ error: 'Failed to update field' });
    }
};

const deleteField = async (req, res) => {
    try {
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? null : req.user.customerId;
        await fieldService.deleteField(req.params.id, customerId);
        res.status(204).send();
    } catch (error) {
        if (error.message === 'Field not found') return res.status(404).json({ error: error.message });
        console.error('Error deleting field:', error);
        res.status(500).json({ error: 'Failed to delete field' });
    }
};

module.exports = { getFields, getFieldById, createField, updateField, deleteField };
