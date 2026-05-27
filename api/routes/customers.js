const express = require('express');
const router = express.Router();
const customers = require('../controllers/customers');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

router.get('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), customers.getCustomers);
router.get('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), customers.getCustomerById);
router.post('/', authorize(['MACSOFT_ADMIN']), customers.createCustomer);
router.put('/:id', authorize(['MACSOFT_ADMIN']), customers.updateCustomer);
router.delete('/:id', authorize(['MACSOFT_ADMIN']), customers.deleteCustomer);

module.exports = router;
