const express = require('express');
const router = express.Router();
const valves = require('../controllers/valves');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

router.get('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'END_USER']), valves.getValves);
router.get('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN', 'CUSTOMER_USER', 'END_USER']), valves.getValveById);
router.post('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), valves.createValve);
router.put('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), valves.updateValve);
router.delete('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), valves.deleteValve);

module.exports = router;
