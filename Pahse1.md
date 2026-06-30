# Phase 1 UI Structure (MVP)

## Admin Panel

```text
Admin Panel
│
├── Authentication
│   └── Login
│
├── Dashboard
│   ├── KPI Cards
│   ├── Live Device Status
│   ├── Running Irrigation
│   ├── Active Alerts
│   └── Recent Commands
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
│       │       ├── Devices
│       │       │   │
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
    ├── Users
    ├── Roles
    └── Company
```

---

# Farmer Mobile App

```text
Farmer App
│
├── Home
│   ├── Current Irrigation
│   ├── Running Zones
│   ├── Water Usage
│   ├── Tank Level
│   ├── Moisture
│   └── Alerts
│
├── Fields
│   ├── Field List
│   └── Field Details
│       ├── Zones
│       ├── Devices
│       ├── Irrigation
│       ├── Schedules
│       └── History
│
├── Irrigation
│   ├── Zone List
│   ├── Manual Start
│   ├── Manual Stop
│   └── Running Irrigation
│
├── Schedules
│   ├── List
│   ├── Create
│   ├── Edit
│   └── History
│
├── Support
│   ├── Create Ticket
│   └── My Tickets
│
└── Profile
    ├── My Account
    ├── Notifications
    ├── Settings
    └── Logout
```

## Phase 1 Development Order

1. Authentication
2. Dashboard
3. Farmer Management
4. Field Management
5. Device Management (Master → Slave → Valve)
6. Zone Management
7. Manual Irrigation
8. Scheduling
9. Monitoring
10. Farmer Mobile App
