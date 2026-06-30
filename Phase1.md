I would be ruthless about Phase 1. **Anything that doesn't help install, monitor, or irrigate should be postponed.**

---

# Admin Panel (Phase 1)

## 1. Login

* Login
* Forgot Password

---

## 2. Dashboard ⭐⭐⭐⭐⭐

### Cards

* Farmers
* Fields
* Masters Online
* Slaves Online
* Running Zones
* Active Alerts

### Live

* Recent Commands
* Offline Devices
* Running Irrigation

### Quick Actions

* Add Farmer
* Add Device
* Start Zone

---

## 3. Farmers ⭐⭐⭐⭐⭐

### List

* Search
* Add Farmer
* Edit
* Delete

### Details

#### General

* Farmer Information

#### Fields

* View Fields
* Add Field

---

## 4. Field Details ⭐⭐⭐⭐⭐

This becomes the main management page.

### Tabs

```
Overview
Zones
Devices
Schedules
History
```

---

## 5. Devices ⭐⭐⭐⭐⭐

### Master

* Add Master
* Edit
* Device Status
* Heartbeat

### Slave

* Add Slave
* Edit
* Modbus Address
* Status

### Valve

* Add Valve
* Rename
* Test Valve
* Open
* Close

---

## 6. Zone Management ⭐⭐⭐⭐⭐

This is one of the most important pages.

### Zone List

```
Tomato

Banana

Cotton
```

### Zone Editor

```
Zone Name

Available Valves

Assigned Valves

Save
```

---

## 7. Manual Irrigation ⭐⭐⭐⭐⭐

```
Field

↓

Zone

↓

Duration

↓

START
```

Running Zones

Emergency Stop

---

## 8. Scheduling ⭐⭐⭐⭐⭐

List

Create

Edit

Delete

Pause

Resume

---

## 9. Live Monitor ⭐⭐⭐⭐

```
Master

↓

Slave

↓

Valve
```

Live Status

Heartbeat

Running Valve

---

## 10. Support ⭐⭐⭐

Tickets

View

Assign

Close

---

## Farmer Mobile

Only five main tabs.

---

## Home ⭐⭐⭐⭐⭐

Cards

* Current Irrigation
* Water Usage
* Tank Level
* Moisture
* Alerts

---

## Fields ⭐⭐⭐⭐⭐

Field List

Field Details

---

## Irrigation ⭐⭐⭐⭐⭐

Zone List

Start

Stop

Running Timer

---

## Schedule ⭐⭐⭐⭐⭐

List

Create

Edit

Delete

---

## Profile ⭐⭐⭐

Profile

Support

Settings

---

# Navigation

## Admin Sidebar

```
Dashboard

Farmers
    Fields

Devices
    Masters
    Slaves
    Valves

Zones

Irrigation

Schedules

Live Monitor

Support

Settings
```

---

## Farmer Bottom Navigation

```
🏠 Home

🌱 Irrigation

📅 Schedule

🌾 Fields

👤 Profile
```

---

# Screens We Should NOT Build in Phase 1

* ❌ Inventory
* ❌ Products
* ❌ Orders
* ❌ Billing
* ❌ Distributor Portal
* ❌ Dealer Portal
* ❌ Warehouse
* ❌ Analytics Dashboard
* ❌ AI Disease Detection
* ❌ OTA Firmware Management UI
* ❌ Notification Rule Builder
* ❌ Advanced Reports
* ❌ Audit Logs
* ❌ Multi-company Management

These can all wait until Phase 2.

## Goal of Phase 1

By the end of Phase 1, a technician should be able to:

1. Create a farmer.
2. Add a field.
3. Register a master controller.
4. Register slave boards.
5. Configure valves.
6. Create irrigation zones.
7. Test valves.
8. Create irrigation schedules.
9. Start/stop irrigation manually.
10. Monitor live device status.
11. Allow the farmer to control irrigation from the mobile app.

If those 11 workflows are complete and reliable, you have a viable MVP ready for pilot deployments.
