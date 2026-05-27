// services/socket.js
// Singleton Socket.IO instance — initialise once from bin/www, import anywhere to emit.

const { Server } = require('socket.io');

let io = null;

/**
 * Call once from the HTTP server bootstrap (bin/www).
 * @param {import('http').Server} httpServer
 */
function init(httpServer) {
    io = new Server(httpServer, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST'],
        },
        path: '/ws',
    });

    io.on('connection', (socket) => {
        console.log(`[ws] client connected: ${socket.id}`);

        // Client subscribes to a specific device room
        socket.on('subscribe:device', (deviceId) => {
            socket.join(`device:${deviceId}`);
/*             console.log(`[ws] ${socket.id} subscribed to device:${deviceId}`);
 */        });

        socket.on('unsubscribe:device', (deviceId) => {
            socket.leave(`device:${deviceId}`);
        });

        // Client subscribes to all-devices feed (used by the dashboard list view)
        socket.on('subscribe:all-devices', () => {
            socket.join('all-devices');
/*             console.log(`[ws] ${socket.id} subscribed to all-devices`);
 */        });

        socket.on('unsubscribe:all-devices', () => {
            socket.leave('all-devices');
        });

        socket.on('disconnect', () => {
/*             console.log(`[ws] client disconnected: ${socket.id}`);
 */        });
    });

    return io;
}

/** Get the initialised instance (throws if init() hasn't been called). */
function getIO() {
    if (!io) throw new Error('Socket.IO not initialised — call init(httpServer) first');
    return io;
}

/**
 * Emit a telemetry row to all clients watching a device.
 * @param {string} deviceId  - UUID
 * @param {object} row       - telemetry record
 */
function emitTelemetry(deviceId, row) {
    if (!io) return; // no-op if WS not running (e.g. standalone ingestion test)
    io.to(`device:${deviceId}`).emit('telemetry', row);
    // Also broadcast to the global dashboard feed so the list view stays current
    io.to('all-devices').emit('device:telemetry', { deviceId, row });
}

module.exports = { init, getIO, emitTelemetry };
