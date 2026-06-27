# System Architecture

## Physical Architecture

```text
                     Cloud Backend
                (Node API + MQTT Broker)
                           │
                     MQTT / HTTPS
                           │
                  Master Controller
           (MQTT Client + Modbus Master)
                           │
                       RS485 Bus
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
 ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
 │   Slave 1   │    │   Slave 2   │    │   Slave 3   │
 │ Unit ID : 1 │    │ Unit ID : 2 │    │ Unit ID : 3 │
 ├─────────────┤    ├─────────────┤    ├─────────────┤
 │ Coil 0 → V1 │    │ Coil 0 → V4 │    │ Coil 0 → V6 │
 │ Coil 1 → V2 │    │ Coil 1 → V5 │    │ Coil 1 → V7 │
 │ Coil 2 → V3 │    │ Coil 2 → V8 │    │ Coil 2 → V9 │
 └─────────────┘    └─────────────┘    └─────────────┘
```

* Master acts as the **Modbus RTU Master (Client)**.
* Slaves act as **Modbus RTU Slaves (Servers)**.
* Each valve is physically wired to exactly one slave output (coil).

---

## Logical Architecture

```text
Farmer
   │
   └── Field
         │
         ├── Master
         │
         ├── Zone : Tomato
         │      ├── Valve 2 (Slave 1, Coil 1)
         │      ├── Valve 4 (Slave 2, Coil 0)
         │      └── Valve 7 (Slave 3, Coil 1)
         │
         └── Zone : Banana
                ├── Valve 1 (Slave 1, Coil 0)
                ├── Valve 5 (Slave 2, Coil 1)
                └── Valve 6 (Slave 3, Coil 0)
```

### Physical Relationship

```
Master
   │
   └── Slave
          │
          └── Valve
```

### Logical Relationship

```
Field
   │
   └── Zone
          │
          └── Valve
```

---

## Valve Identity

Every valve has:

### Physical Identity

* Master ID
* Slave ID
* Modbus Unit ID
* Coil Address

Example:

```
Valve 7

Slave ID        : 3
Unit ID         : 3
Coil Address    : 1
```

### Logical Identity

* Field
* Zone
* Valve Name

Example:

```
Field : North Farm
Zone  : Tomato
Valve : Tomato East
```

---

## Command Flow

```
Mobile App
      │
      ▼
Backend
      │
      ▼
Find all valves in Zone "Tomato"
      │
      ▼
Valve 2 → Slave 1 → Coil 1
Valve 4 → Slave 2 → Coil 0
Valve 7 → Slave 3 → Coil 1
      │
      ▼
Publish MQTT Command
      │
      ▼
Master Controller
      │
      ▼
Generate Modbus RTU Frames
      │
      ▼
RS485 Bus
      │
      ▼
Slave Devices
      │
      ▼
Operate Physical Valves
      │
      ▼
Return ACK
      │
      ▼
Master publishes status to MQTT
      │
      ▼
Backend updates irrigation status
```

---

## Design Principle

* **Backend** manages farmers, fields, zones, schedules, valves, and business logic.
* **Master** translates backend commands into Modbus RTU communication.
* **Slave** only controls hardware outputs (coils) and sensors.
* **Valve** is the bridge between the logical irrigation model (zones) and the physical Modbus network (slaves).
* **Zones are logical groups of valves**, while **slaves are physical controllers**.
