const express = require('express');
const router = express.Router();
const zones = require('../controllers/zones');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

router.get('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'END_USER']), zones.getZones);
router.get('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'END_USER']), zones.getZoneById);
router.post('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), zones.createZone);
router.put('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), zones.updateZone);
router.delete('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), zones.deleteZone);

module.exports = router;
