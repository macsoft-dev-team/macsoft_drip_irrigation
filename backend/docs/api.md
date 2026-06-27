# API Reference

Base URL:

```text
/api/v1
```

Authentication:

```http
Authorization: Bearer <jwt>
```

## Auth

```http
POST /auth/registerFarmer
POST /auth/login
GET  /auth/me
```

## Fields

```http
GET    /fields
POST   /fields
GET    /fields/:fieldId
PATCH  /fields/:fieldId
DELETE /fields/:fieldId
```

## Master Controllers

```http
POST  /fields/:fieldId/masterController
GET   /fields/:fieldId/masterController
PATCH /masterControllers/:masterControllerId
```

## Zones

```http
GET    /fields/:fieldId/zones
POST   /fields/:fieldId/zones
PATCH  /zones/:zoneId
DELETE /zones/:zoneId
```

## Valves

```http
GET    /zones/:zoneId/valves
POST   /zones/:zoneId/valves
PATCH  /valves/:valveId
DELETE /valves/:valveId
```

## Commands

```http
POST /commands/valves/:valveId/open
POST /commands/valves/:valveId/close
POST /commands/zones/:zoneId/open
POST /commands/zones/:zoneId/close
GET  /commands
GET  /commands/:commandId
```

## Device HTTP fallback

MQTT is the primary device protocol. These endpoints exist only as fallback/testing APIs.

```http
POST /device/masters/:deviceUid/heartbeat
POST /device/masters/:deviceUid/ack
```

## Schedules

```http
GET    /schedules
POST   /schedules
PATCH  /schedules/:scheduleId
DELETE /schedules/:scheduleId
```

## Products and Orders

```http
GET  /products
POST /products
POST /orders
GET  /orders
```

## Support Tickets

```http
GET   /supportTickets
POST  /supportTickets
PATCH /supportTickets/:ticketId
```

## Admin

```http
GET /admin/farmers
GET /admin/farmers/:farmerId/overview
GET /admin/commands
```
