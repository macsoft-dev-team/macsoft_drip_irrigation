MQTT Message
│
▼
Receive Command
│
▼
Resolve Zone → Valves
│
▼
Group by Slave
│
▼
Slave 1 → Coils 1,2
Slave 2 → Coil 0
Slave 3 → Coil 1
│
▼
Generate Optimized Modbus Frames
│
▼
Slave 1 → Function 15 (Write Multiple Coils)
Slave 2 → Function 05 (Write Single Coil)
Slave 3 → Function 05 (Write Single Coil)
│
▼
RS485 UART
│
▼
Slave Devices
│
▼
ACK / Error Response
│
▼
Publish Result to MQTT
