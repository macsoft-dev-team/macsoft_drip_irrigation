 
## Organization Roles

### 1. Super Admin

* Manage the entire platform
* Manage all users
* Manage firmware
* View all customers
* System configuration

---

### 2. Sales

* Register new customers
* Create quotations
* Register farmers
* Assign devices after purchase
* View customer information
* Cannot control irrigation

---

### 3. Service / Customer Care

* View customer devices
* Diagnose device issues
* Check online/offline status
* View logs
* Assist customers
* Trigger remote tests
* Cannot delete data or transfer ownership

---

### 4. Installation Technician

* Install master
* Install slaves
* Configure Modbus addresses
* Add valves
* Create zones
* Test valves
* Configure sensors
* Commission the system

---

### 5. Farmer (Owner)

* Manage fields
* Manage zones
* Create schedules
* Start/Stop irrigation
* View reports
* Invite farm users

---

### 6. Farm Manager

* Operate irrigation
* Create schedules
* View reports
* Manage workers

---

### 7. Operator / Worker

* Start/Stop irrigation
* View assigned fields
* View valve status only

---

## Permission Matrix

| Feature           | Super Admin | Sales |    Service    | Technician | Farmer | Manager | Operator |
| ----------------- | :---------: | :---: | :-----------: | :--------: | :----: | :-----: | :------: |
| Add Customer      |      ✅      |   ✅   |       ❌       |      ❌     |    ❌   |    ❌    |     ❌    |
| Edit Customer     |      ✅      |   ✅   |       ✅       |      ❌     |    ❌   |    ❌    |     ❌    |
| Install Devices   |      ✅      |   ❌   |       ❌       |      ✅     |    ❌   |    ❌    |     ❌    |
| Configure Modbus  |      ✅      |   ❌   |       ❌       |      ✅     |    ❌   |    ❌    |     ❌    |
| Add Valves        |      ✅      |   ❌   |       ❌       |      ✅     |    ❌   |    ❌    |     ❌    |
| Create Zones      |      ✅      |   ❌   |       ❌       |      ✅     |    ✅   |    ❌    |     ❌    |
| Create Schedule   |      ✅      |   ❌   |       ❌       |      ❌     |    ✅   |    ✅    |     ❌    |
| Manual Irrigation |      ✅      |   ❌   | ✅ (if needed) |      ✅     |    ✅   |    ✅    |     ✅    |
| View Device Logs  |      ✅      |   ❌   |       ✅       |      ✅     |    ✅   |    ✅    |     ❌    |
| OTA Update        |      ✅      |   ❌   |       ✅       |      ✅     |    ❌   |    ❌    |     ❌    |

## Suggested Roles Table

```text
roles
-----
SUPER_ADMIN
SALES
SERVICE
TECHNICIAN
FARMER
FARM_MANAGER
OPERATOR
```

This role structure works well because it separates responsibilities:

* **Sales** focuses on customer onboarding and commercial activities.
* **Service/Customer Care** provides remote support and troubleshooting.
* **Technicians** handle installation and hardware configuration.
* **Farmers and farm staff** manage day-to-day irrigation operations.
