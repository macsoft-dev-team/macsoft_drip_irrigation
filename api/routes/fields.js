const express = require('express');
const router = express.Router();
const fields = require('../controllers/fields');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

router.get('/', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'CUSTOMER']), fields.getFields);
router.get('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'CUSTOMER']), fields.getFieldById);
router.post('/', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), fields.createField);
router.put('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), fields.updateField);
router.delete('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), fields.deleteField);

module.exports = router;
