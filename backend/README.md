# Drip Irrigation SaaS API

Backend API for a SaaS drip irrigation platform where farmers buy devices, manage fields, zones, valves, and your team/distributors remotely support devices.

## Architecture

```text
Flutter App / Admin Panel
        ↓ REST + Socket.IO
Node.js Express API
        ↓ Prisma ORM
MySQL
        ↓ BullMQ
Redis Queue
        ↓ MQTT
Master Controller
        ↓ wired / local protocol
Valves
```

## Important domain rule

```text
Farmer → Field → Zone → Valve
              ↓
        Master Controller
```

Each field has exactly one master controller. The cloud never talks directly to valves. The cloud sends commands to the field master controller, and the master controller sends commands to valves.

## Stack

- Node.js + TypeScript + Express
- Prisma ORM v7 + MySQL
- Redis + BullMQ for command queue and retry
- MQTT for backend ↔ master controller messaging
- Socket.IO for live app/admin status updates

## Local setup

```bash
cp .env.example .env
docker compose up -d
npm install
npm run prisma:generate
npm run prisma:migrate
npm run prisma:seed
npm run dev
docker ps -a
docker logs dripMqtt
docker compose down
```


For production you should normally bundle the API with a build tool such as tsup or run it through your process manager using `npm start`.

The API runs on:

```text
http://localhost:4000/api/v1
```

Health check:

```bash
curl http://localhost:4000/health
```

## Default seed users

```text
Admin:
phone: 9999999999
password: admin12345

Farmer:
phone: 8888888888
password: farmer12345
```

## Main API groups

```text
/auth
/fields
/zones
/valves
/masterControllers
/commands
/schedules
/products
/orders
/servicePlans
/supportTickets
/admin
/device
```

## Command workflow

Manual valve command:

```text
POST /api/v1/commands/valves/:valveId/open
        ↓
Create command + commandItems
        ↓
Queue command in BullMQ
        ↓
Worker publishes MQTT command
        ↓
Master controller executes valve operation
        ↓
Master sends MQTT ack
        ↓
API updates command, commandItems, valve statuses
        ↓
Socket.IO broadcasts update to app/admin
```

See `docs/workflows.md` and `docs/api.md`.

## MQTT topics

Commands to master:

```text
farm/{farmerId}/field/{fieldId}/master/{deviceUid}/command
```

Master acknowledgement:

```text
farm/{farmerId}/field/{fieldId}/master/{deviceUid}/ack
```

Master heartbeat:

```text
farm/{farmerId}/field/{fieldId}/master/{deviceUid}/heartbeat
```

Master status report:

```text
farm/{farmerId}/field/{fieldId}/master/{deviceUid}/status
```

## Notes for hardware team

The master controller should maintain command idempotency. If it receives the same `commandUid` again, it should return the previous ACK instead of executing the valve twice.

## Production checklist

- Use a managed MySQL database.
- Use managed Redis or Redis cluster.
- Use EMQX/HiveMQ/AWS IoT Core instead of local Mosquitto.
- Disable anonymous MQTT.
- Use per-device credentials/certificates.
- Add rate limiting.
- Add audit logs before giving admin/support access to production.
- Configure backups and migration rollback process.
