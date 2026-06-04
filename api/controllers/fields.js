const fieldService = require('../services/fields');

const getFields = async (req, res) => {
    try {
        const { skip, take, filter } = req.query;
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? (req.query.tenantId || null) : req.user.tenantId;

        const { fields, count } = await fieldService.getFields(tenantId, skip, take, filter);
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
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? null : req.user.tenantId;
        const field = await fieldService.getFieldById(req.params.id, tenantId);
        res.status(200).json(field);
    } catch (error) {
        if (error.message === 'Field not found') return res.status(404).json({ error: error.message });
        console.error('Error fetching field:', error);
        res.status(500).json({ error: 'Failed to fetch field' });
    }
};

const createField = async (req, res) => {
    try {
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? req.body.tenantId : req.user.tenantId;
        if (!tenantId) {
            return res.status(400).json({ error: 'TenantId is required' });
        }
        const field = await fieldService.createField({
            name: req.body.name,
            tenantId
        });
        res.status(201).json(field);
    } catch (error) {
        console.error('Error creating field:', error);
        res.status(500).json({ error: 'Failed to create field' });
    }
};

const updateField = async (req, res) => {
    try {
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? null : req.user.tenantId;
        const field = await fieldService.updateField(req.params.id, req.body, tenantId);
        res.status(200).json(field);
    } catch (error) {
        if (error.message === 'Field not found') return res.status(404).json({ error: error.message });
        console.error('Error updating field:', error);
        res.status(500).json({ error: 'Failed to update field' });
    }
};

const deleteField = async (req, res) => {
    try {
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? null : req.user.tenantId;
        await fieldService.deleteField(req.params.id, tenantId);
        res.status(204).send();
    } catch (error) {
        if (error.message === 'Field not found') return res.status(404).json({ error: error.message });
        console.error('Error deleting field:', error);
        res.status(500).json({ error: 'Failed to delete field' });
    }
};

module.exports = { getFields, getFieldById, createField, updateField, deleteField };
