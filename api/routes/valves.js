const express = require('express');
const router = express.Router();
const valves = require('../controllers/valves');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

router.get('/', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'CUSTOMER']), valves.getValves);
router.get('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'CUSTOMER']), valves.getValveById);
router.post('/', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), valves.createValve);
router.put('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), valves.updateValve);
router.delete('/:id', authorize(['SYSTEM_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER']), valves.deleteValve);

module.exports = router;
