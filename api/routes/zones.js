const express = require('express');
const router = express.Router();
const zones = require('../controllers/zones');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

router.get('/', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'CUSTOMER']), zones.getZones);
router.get('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'CUSTOMER']), zones.getZoneById);
router.post('/', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), zones.createZone);
router.put('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), zones.updateZone);
router.delete('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), zones.deleteZone);

module.exports = router;
