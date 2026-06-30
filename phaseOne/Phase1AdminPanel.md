# Phase 1 Admin Panel (Priority)

```text
Admin Panel
│
├── Authentication
│   ├── Login
│   └── Users
│       ├── List
│       ├── Create
│       ├── Edit
│       ├── Roles
│       └── Permissions
│
├── Dashboard
│
├── Farmers
│   ├── Farmer List
│   ├── Create Farmer
│   ├── Edit Farmer
│   └── Farmer Details
│       │
│       ├── Overview
│       │
│       ├── Fields
│       │   ├── Field List
│       │   ├── Create Field
│       │   ├── Edit Field
│       │   └── Field Details
│       │       │
│       │       ├── Overview
│       │       │
│       │       ├── Commissioning
│       │       │   ├── Register Master
│       │       │   ├── Add Slave Boards
│       │       │   ├── Configure Modbus Address
│       │       │   ├── Add Valves
│       │       │   ├── Test Valves
│       │       │   └── Assign Valves to Zones
│       │       │
│       │       ├── Devices
│       │       │   ├── Master Controller
│       │       │   │   ├── Device Information
│       │       │   │   ├── Heartbeat
│       │       │   │   ├── Connectivity
│       │       │   │   └── Edit Configuration
│       │       │   │
│       │       │   ├── Slave Boards
│       │       │   │   ├── List
│       │       │   │   ├── Add Slave
│       │       │   │   ├── Edit Slave
│       │       │   │   ├── Modbus Address
│       │       │   │   └── Test Communication
│       │       │   │
│       │       │   └── Valves
│       │       │       ├── List
│       │       │       ├── Add Valve
│       │       │       ├── Rename
│       │       │       ├── Test Valve
│       │       │       ├── Open
│       │       │       └── Close
│       │       │
│       │       ├── Zones
│       │       │   ├── Zone List
│       │       │   ├── Create Zone
│       │       │   ├── Edit Zone
│       │       │   ├── Assign Valves
│       │       │   ├── Start Zone
│       │       │   └── Stop Zone
│       │       │
│       │       ├── Irrigation
│       │       │   ├── Manual Irrigation
│       │       │   ├── Running Zones
│       │       │   ├── Emergency Stop
│       │       │   └── History
│       │       │
│       │       ├── Schedules
│       │       │   ├── List
│       │       │   ├── Create
│       │       │   ├── Edit
│       │       │   ├── Pause
│       │       │   └── History
│       │       │
│       │       └── Monitoring
│       │           ├── Live Status
│       │           ├── Heartbeats
│       │           ├── Telemetry
│       │           └── Command History
│       │
│       ├── Support
│       └── Activity
│
├── Support
│   ├── Ticket List
│   └── Ticket Details
│
└── Settings
    ├── Company
    ├── MQTT
    └── Roles & Permissions
```
