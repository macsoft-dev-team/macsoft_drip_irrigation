Yes, for **Phase 1** this is a clean architecture. I would make one small improvement by showing the backend separately from the device communication.

```text
                ┌─────────────────────┐
                │  Farmer Mobile App  │
                └──────────┬──────────┘
                           │
                      HTTP / WebSocket
                           │
                ┌──────────▼──────────┐
                │    Node.js Backend  │
                │   REST + WebSocket  │
                └──────────┬──────────┘
                           │
                     Local WiFi LAN
                           │
                ┌──────────▼──────────┐
                │ Raspberry Pi Master │
                │ Modbus TCP Client   │
                └──────────┬──────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
      ┌────────────┐ ┌────────────┐ ┌────────────┐
      │ ESP32      │ │ ESP32      │ │ ESP32      │
      │ Slave #1   │ │ Slave #2   │ │ Slave #3   │
      │ TCP Server │ │ TCP Server │ │ TCP Server │
      │ Unit ID: 1 │ │ Unit ID: 2 │ │ Unit ID: 3 │
      └────────────┘ └────────────┘ └────────────┘
              │            │            │
           Valves       Valves       Valves
```

## Communication Flow

```text
Farmer Mobile / Admin Web

↓

HTTP REST

↓

Node.js Backend

↓

HTTP/WebSocket

↓

Master Controller

↓

Modbus TCP

↓

ESP32 Slave

↓

Valve
```

---

## Device Communication

| Source     | Destination | Protocol              |
| ---------- | ----------- | --------------------- |
| Mobile App | Backend     | HTTP REST + WebSocket |
| Admin Web  | Backend     | HTTP REST + WebSocket |
| Backend    | Master      | HTTP REST / WebSocket |
| Master     | Slave       | Modbus TCP            |
| Slave      | Valve       | GPIO                  |

---

## Slave Configuration

Each slave stores:

```text
Name

IP Address

Port (502)

Unit ID

Number of Outputs
```

Example

| Slave   | IP Address    | Port | Unit ID |
| ------- | ------------- | ---- | ------- |
| Slave 1 | 192.168.1.101 | 502  | 1       |
| Slave 2 | 192.168.1.102 | 502  | 2       |
| Slave 3 | 192.168.1.103 | 502  | 3       |

---

## Example

The farmer starts the **Tomato Zone**.

```text
Mobile App
    │
    ▼
POST /api/irrigation/start-zone
{
  "zoneId": 5
}

↓

Backend

↓

POST /master/execute

↓

Master

↓

192.168.1.101
Write Coil 1 = ON

↓

192.168.1.102
Write Coil 0 = ON

↓

192.168.1.103
Write Coil 2 = ON

↓

ESP32 Slaves

↓

Relays ON

↓

Valves Open
```

## Why this is a good Phase 1 design

* **Simple to develop:** No RS485 hardware or serial debugging during the MVP.
* **Easy debugging:** Each ESP32 has its own IP address and can be reached over WiFi.
* **Production-ready logic:** The backend still communicates only with the Master, preserving your intended architecture.
* **Future-proof:** When you move to RS485 Modbus RTU later, only the **Master ↔ Slave communication layer** changes. The mobile app, web app, backend APIs, database, and UI remain the same.
