const express = require('express');
const router = express.Router();
const tenants = require('../controllers/tenants');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

router.get('/', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN']), tenants.getTenants);
router.get('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN']), tenants.getTenantById);
router.post('/', authorize(['SYSTEM_ADMIN']), tenants.createTenant);
router.put('/:id', authorize(['SYSTEM_ADMIN']), tenants.updateTenant);
router.delete('/:id', authorize(['SYSTEM_ADMIN']), tenants.deleteTenant);

module.exports = router;
