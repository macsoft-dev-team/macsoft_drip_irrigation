module.exports = {
    apps: [
        {
            "name": 'Macsoft Drip Irrigation API',
            "script": './bin/www',
            "watch": '.',
            "max_memory_restart": '512M',
            "env_development": {
                "NODE_ENV": 'development',
                "DATABASE_URL": "postgresql://Welcome123!@localhost:5432/hnsdev",
                "PORT": 3579,
                "JWT_SECRET_KEY": "mnedwverutterunderramcommand",
                "MQTT_BROKER_URL": "mqtt://localhost:1883"
            },
            "env_production": {
                "NODE_ENV": 'production',
                "DATABASE_URL": "postgresql://root:Welcome123!@localhost:5432/hns",
                "PORT": 3579,
                "JWT_SECRET_KEY": "mnedwverutterunderramcommand",
                "MQTT_BROKER_URL": "mqtt://mqtt.macsoftautomations.in:1883",
                "MQTT_USERNAME": "admin",
                "MQTT_PASSWORD": "admin",
                "MQTT_CLIENT_ID": "hns-device-listener",
            }
        }
    ]
};