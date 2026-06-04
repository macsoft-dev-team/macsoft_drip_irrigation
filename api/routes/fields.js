const express = require('express');
const router = express.Router();
const fields = require('../controllers/fields');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

router.get('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'END_USER']), fields.getFields);
router.get('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'END_USER']), fields.getFieldById);
router.post('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), fields.createField);
router.put('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), fields.updateField);
router.delete('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), fields.deleteField);

module.exports = router;
