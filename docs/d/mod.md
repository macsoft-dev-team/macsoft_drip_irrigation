# Database Model

## Physical Hierarchy

```text
Farmer
    │
    ├── Field
    │      │
    │      ├── Master
    │      │      │
    │      │      ├── Slave (Modbus Unit ID = 1)
    │      │      │      ├── Valve 1 (Coil 0)
    │      │      │      ├── Valve 2 (Coil 1)
    │      │      │      └── Valve 3 (Coil 2)
    │      │      │
    │      │      ├── Slave (Modbus Unit ID = 2)
    │      │      │      ├── Valve 4 (Coil 0)
    │      │      │      ├── Valve 5 (Coil 1)
    │      │      │
    │      │      └── Slave (Modbus Unit ID = 3)
    │      │             ├── Valve 6 (Coil 0)
    │      │             └── Valve 7 (Coil 1)
    │      │
    │      └── Zones
    │             ├── Tomato
    │             │      ├── Valve 2 (Slave 1)
    │             │      ├── Valve 4 (Slave 2)
    │             │      └── Valve 7 (Slave 3)
    │             │
    │             └── Banana
    │                    ├── Valve 1
    │                    └── Valve 6
```

### Relationships

* Farmer → Multiple Fields
* Field → One Master
* Master → Multiple Slaves
* Slave → Multiple Valves
* Zone → Multiple Valves
* Valve → Exactly One Zone
* Valve → Exactly One Slave

A valve has two identities:

* Physical → Connected to a Slave through a Coil Address.
* Logical → Assigned to a Zone.

---

# Database Tables

## Farmer

```sql
id
name
phone
```

## Field

```sql
id
farmer_id
name
location
```

## Master

```sql
id
field_id
serial_no
firmware_version
status
```

## Slave

```sql
id
master_id
name
modbus_address
firmware_version
status
```

## Zone

```sql
id
field_id
name
description
```

## Valve

```sql
id
slave_id
zone_id
name
coil_address
status
```

Example:

| Valve   | Zone   | Slave   | Modbus Address | Coil |
| ------- | ------ | ------- | -------------- | ---- |
| Valve 1 | Banana | Slave 1 | 1              | 0    |
| Valve 2 | Tomato | Slave 1 | 1              | 1    |
| Valve 3 | Tomato | Slave 1 | 1              | 2    |
| Valve 4 | Tomato | Slave 2 | 2              | 0    |
| Valve 5 | Banana | Slave 2 | 2              | 1    |
| Valve 6 | Banana | Slave 3 | 3              | 0    |
| Valve 7 | Tomato | Slave 3 | 3              | 1    |

---

# Communication Architecture

```text
                Cloud Backend
           (API + MQTT Broker)
                    │
              MQTT / HTTPS
                    │
            Master Controller
      (MQTT Client + Modbus Master)
                    │
                 RS485 Bus
                    │
      ┌─────────────┼─────────────┐
      │             │             │
  Slave 1       Slave 2       Slave 3
(Unit ID 1)   (Unit ID 2)   (Unit ID 3)
      │             │             │
 Coil0 Coil1    Coil0 Coil1   Coil0 Coil1
   │      │        │      │      │      │
 Valve1 Valve2  Valve4 Valve5 Valve6 Valve7
```

The Master is the Modbus RTU Master (Client).

Each Slave is a Modbus RTU Slave (Server).

The Slave only understands Modbus Coils and Registers.

It has no knowledge of:

* Farmers
* Fields
* Zones
* Valve Names
* Schedules

---

# Example: Start Tomato Zone

Tomato Zone contains:

| Valve   | Slave   | Unit ID | Coil |
| ------- | ------- | ------- | ---- |
| Valve 2 | Slave 1 | 1       | 1    |
| Valve 3 | Slave 1 | 1       | 2    |
| Valve 4 | Slave 2 | 2       | 0    |
| Valve 7 | Slave 3 | 3       | 1    |

The backend executes:

```sql
SELECT
    s.modbus_address,
    v.coil_address
FROM valve v
JOIN slave s ON s.id = v.slave_id
WHERE v.zone_id = 1;
```

The backend publishes a high-level MQTT command:

```json
{
  "command": "START_ZONE",
  "zoneId": 1
}
```

or

```json
{
  "command": "START_ZONE",
  "valves": [
    { "slave": 1, "coil": 1 },
    { "slave": 1, "coil": 2 },
    { "slave": 2, "coil": 0 },
    { "slave": 3, "coil": 1 }
  ]
}
```

---

# Modbus RTU Communication

The Master translates the valve list into Modbus RTU frames.

To Slave 1:

```
01 05 00 01 FF 00 CRC
```

```
01 05 00 02 FF 00 CRC
```

To Slave 2:

```
02 05 00 00 FF 00 CRC
```

To Slave 3:

```
03 05 00 01 FF 00 CRC
```

Each Slave:

1. Checks the Unit ID.
2. Verifies the CRC.
3. Updates the requested Coil.
4. Turns the relay ON/OFF.
5. Returns a Modbus response.

---

# Optimization

If multiple valves belong to the same Slave, the Master groups them and uses **Modbus Function Code 15 (Write Multiple Coils)** instead of multiple Function Code 05 requests.

Example:

Slave 1 needs:

* Coil 1 = ON
* Coil 2 = ON

Instead of:

```
01 05 00 01 FF 00 CRC
01 05 00 02 FF 00 CRC
```

The Master sends a single request:

```
01 0F 00 01 00 02 01 03 CRC
```

This reduces RS485 traffic, improves performance, and is the preferred approach for industrial Modbus RTU systems.
