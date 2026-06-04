const zoneService = require('../services/zones');

const getZones = async (req, res) => {
    try {
        const { skip, take, filter, fieldId } = req.query;
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? (req.query.tenantId || null) : req.user.tenantId;

        const { zones, count } = await zoneService.getZones(tenantId, fieldId, skip, take, filter);
        res.status(200).json({
            zones,
            totalPages: Math.ceil(count / (parseInt(take) || 100)),
            currentPage: parseInt(req.query.skip) || 1,
            totalCount: count
        });
    } catch (error) {
        console.error('Error fetching zones:', error);
        res.status(500).json({ error: 'Failed to fetch zones' });
    }
};

const getZoneById = async (req, res) => {
    try {
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? null : req.user.tenantId;
        const zone = await zoneService.getZoneById(req.params.id, tenantId);
        res.status(200).json(zone);
    } catch (error) {
        if (error.message === 'Zone not found') return res.status(404).json({ error: error.message });
        console.error('Error fetching zone:', error);
        res.status(500).json({ error: 'Failed to fetch zone' });
    }
};

const createZone = async (req, res) => {
    try {
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? null : req.user.tenantId;
        const zone = await zoneService.createZone(req.body, tenantId);
        res.status(201).json(zone);
    } catch (error) {
        if (error.message.includes('not found') || error.message.includes('denied')) {
            return res.status(400).json({ error: error.message });
        }
        console.error('Error creating zone:', error);
        res.status(500).json({ error: 'Failed to create zone' });
    }
};

const updateZone = async (req, res) => {
    try {
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? null : req.user.tenantId;
        const zone = await zoneService.updateZone(req.params.id, req.body, tenantId);
        res.status(200).json(zone);
    } catch (error) {
        if (error.message === 'Zone not found') return res.status(404).json({ error: error.message });
        console.error('Error updating zone:', error);
        res.status(500).json({ error: 'Failed to update zone' });
    }
};

const deleteZone = async (req, res) => {
    try {
        const isSystemAdmin = req.user.role === 'SYSTEM_ADMIN';
        const tenantId = isSystemAdmin ? null : req.user.tenantId;
        await zoneService.deleteZone(req.params.id, tenantId);
        res.status(204).send();
    } catch (error) {
        if (error.message === 'Zone not found') return res.status(404).json({ error: error.message });
        console.error('Error deleting zone:', error);
        res.status(500).json({ error: 'Failed to delete zone' });
    }
};

module.exports = { getZones, getZoneById, createZone, updateZone, deleteZone };
