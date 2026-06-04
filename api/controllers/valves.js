const valveService = require('../services/valves');

const getValves = async (req, res) => {
    try {
        const { skip, take, filter, zoneId } = req.query;
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? (req.query.customerId || null) : req.user.customerId;

        const { valves, count } = await valveService.getValves(customerId, zoneId, skip, take, filter);
        res.status(200).json({
            valves,
            totalPages: Math.ceil(count / (parseInt(take) || 100)),
            currentPage: parseInt(req.query.skip) || 1,
            totalCount: count
        });
    } catch (error) {
        console.error('Error fetching valves:', error);
        res.status(500).json({ error: 'Failed to fetch valves' });
    }
};

const getValveById = async (req, res) => {
    try {
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? null : req.user.customerId;
        const valve = await valveService.getValveById(req.params.id, customerId);
        res.status(200).json(valve);
    } catch (error) {
        if (error.message === 'Valve not found') return res.status(404).json({ error: error.message });
        console.error('Error fetching valve:', error);
        res.status(500).json({ error: 'Failed to fetch valve' });
    }
};

const createValve = async (req, res) => {
    try {
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? null : req.user.customerId;
        const valve = await valveService.createValve(req.body, customerId);
        res.status(201).json(valve);
    } catch (error) {
        if (error.message.includes('not found') || error.message.includes('denied')) {
            return res.status(400).json({ error: error.message });
        }
        console.error('Error creating valve:', error);
        res.status(500).json({ error: 'Failed to create valve' });
    }
};

const updateValve = async (req, res) => {
    try {
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? null : req.user.customerId;
        const valve = await valveService.updateValve(req.params.id, req.body, customerId);
        res.status(200).json(valve);
    } catch (error) {
        if (error.message === 'Valve not found') return res.status(404).json({ error: error.message });
        console.error('Error updating valve:', error);
        res.status(500).json({ error: 'Failed to update valve' });
    }
};

const deleteValve = async (req, res) => {
    try {
        const isMacsoftAdmin = req.user.role === 'MACSOFT_ADMIN';
        const customerId = isMacsoftAdmin ? null : req.user.customerId;
        await valveService.deleteValve(req.params.id, customerId);
        res.status(204).send();
    } catch (error) {
        if (error.message === 'Valve not found') return res.status(404).json({ error: error.message });
        console.error('Error deleting valve:', error);
        res.status(500).json({ error: 'Failed to delete valve' });
    }
};

module.exports = { getValves, getValveById, createValve, updateValve, deleteValve };
