const tenantService = require('../services/tenants');

const getTenants = async (req, res) => {
    try {
        const { skip, take, filter } = req.query;
        const { tenants, count } = await tenantService.getTenants(skip, take, filter);
        res.status(200).json({
            tenants,
            totalPages: Math.ceil(count / (parseInt(take) || 10)),
            currentPage: parseInt(req.query.skip) || 1,
        });
    } catch (error) {
        console.error('Error fetching tenants:', error);
        res.status(500).json({ error: 'Failed to fetch tenants' });
    }
};

const getTenantById = async (req, res) => {
    try {
        const tenant = await tenantService.getTenantById(req.params.id);
        res.status(200).json(tenant);
    } catch (error) {
        if (error.message === 'Tenant not found') return res.status(404).json({ error: error.message });
        console.error('Error fetching tenant:', error);
        res.status(500).json({ error: 'Failed to fetch tenant' });
    }
};

const createTenant = async (req, res) => {
    try {
        const tenant = await tenantService.createTenant(req.body);
        res.status(201).json(tenant);
    } catch (error) {
        console.error('Error creating tenant:', error);
        res.status(500).json({ error: 'Failed to create tenant' });
    }
};

const updateTenant = async (req, res) => {
    try {
        const tenant = await tenantService.updateTenant(req.params.id, req.body);
        res.status(200).json(tenant);
    } catch (error) {
        console.error('Error updating tenant:', error);
        res.status(500).json({ error: 'Failed to update tenant' });
    }
};

const deleteTenant = async (req, res) => {
    try {
        await tenantService.deleteTenant(req.params.id);
        res.status(204).send();
    } catch (error) {
        console.error('Error deleting tenant:', error);
        res.status(500).json({ error: 'Failed to delete tenant' });
    }
};

module.exports = { getTenants, getTenantById, createTenant, updateTenant, deleteTenant };
