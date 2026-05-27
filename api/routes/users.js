const express = require('express');
const router = express.Router();
const users = require('../controllers/users');
const { authenticate, authorize } = require('../controllers/auth');

router.use(authenticate);

/* GET users listing. */
router.get('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), users.getUsers);
router.get('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), users.getUserById);
router.post('/', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), users.createUser);
router.put('/:id', authorize(['MACSOFT_ADMIN', 'CUSTOMER_ADMIN']), users.updateUser);
router.delete('/:id', authorize(['MACSOFT_ADMIN']), users.deleteUser);
module.exports = router;
