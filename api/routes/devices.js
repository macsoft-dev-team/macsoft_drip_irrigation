const express = require("express");
const router = express.Router();
const deviceUpload = require("../controllers/devices");
const { authenticate, authorize } = require("../controllers/auth");

const MANAGE_ROLES = ['MACSOFT_ADMIN', 'MACSOFT_USER', 'CUSTOMER_ADMIN'];

router.use(authenticate);

router.get("/", deviceUpload.getDevices);
router.post("/upload", authorize(MANAGE_ROLES), deviceUpload.uploadDevices);
router.post("/", authorize(MANAGE_ROLES), deviceUpload.createDevice);
router.get("/:id", deviceUpload.getDeviceById);
router.put("/:id", authorize(MANAGE_ROLES), deviceUpload.updateDevice);
router.put("/:id/config", authorize(MANAGE_ROLES), deviceUpload.saveDeviceConfig);
router.get("/:id/telemetry", deviceUpload.getDeviceTelemetry);
router.post("/:id/commands", deviceUpload.sendCommand);
router.get("/:id/commands", deviceUpload.getCommands);

module.exports = router;
