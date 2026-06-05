const express = require('express');
const router = express.Router();
const authRouter = require('./auth');
const usersRouter = require('./users');
const devicesRouter = require('./devices');
const tenantsRouter = require('./tenants');
const fieldsRouter = require('./fields');
const zonesRouter = require('./zones');
const valvesRouter = require('./valves');

router.get('/', (req, res) => {
    res.json({ message: 'Welcome to the Drip Irrigation API' });
});

router.use('/auth', authRouter);
router.use('/users', usersRouter);
router.use('/devices', devicesRouter);
router.use('/tenants', tenantsRouter);
router.use('/fields', fieldsRouter);
router.use('/zones', zonesRouter);
router.use('/valves', valvesRouter);

module.exports = router;
