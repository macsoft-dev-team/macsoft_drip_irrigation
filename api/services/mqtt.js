// services/mqtt.js
// Singleton MQTT client used by the API to publish commands.
// The ingestion job has its own subscriber client; this one is publish-only.

const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env'), quiet: true });
const mqtt = require('mqtt');

let _client = null;

function init() {
    if (_client) return _client;

    _client = mqtt.connect(process.env.MQTT_BROKER_URL || 'mqtt://localhost:1883', {
        username: process.env.MQTT_USERNAME,
        password: process.env.MQTT_PASSWORD,
        clientId: `wrms_api_${Date.now()}`,
        clean: true,
    });

    _client.on('connect', () => console.log('[mqtt-api] publisher connected'));
/*     _client.on('error',   (err) => console.error('[mqtt-api] error:', err.message));
 */
    return _client;
}

function publish(topic, payload) {
    if (!_client || !_client.connected) {
        console.warn('[mqtt-api] cannot publish — client not connected');
        return false;
    }
    const msg = typeof payload === 'string' ? payload : JSON.stringify(payload);
    _client.publish(topic, msg, { qos: 1 });
    return true;
}

module.exports = { init, publish };
