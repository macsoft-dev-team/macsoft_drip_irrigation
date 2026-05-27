const express = require('express');
const router = express.Router();
const authRouter = require('./auth');
const usersRouter = require('./users');
const devicesRouter = require('./devices');
const customersRouter = require('./customers');

router.get('/', (req, res) => {
    res.json({ message: 'Welcome to the WRMS API' });
});

router.use('/auth', authRouter);
router.use('/users', usersRouter);
router.use('/devices', devicesRouter);
router.use('/customers', customersRouter);

module.exports = router;
