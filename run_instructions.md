# Setup & Run Commands

## 1. Python AI Service (Backend)

```bash
# Install Python requirements
pip3 install fastapi uvicorn pillow python-multipart

# Navigate and run server (runs on port 8080)
cd ai_service
python3 main.py
```

## 2. Flutter App (Frontend)

```bash
# Fetch package dependencies
cd app
flutter pub get

# Launch Flutter app (Web, Desktop, or Emulator)
flutter run
```
Modbus Master (Raspberry Pi): Located at 

master.py

Handles connection to the MQTT broker, manages background heartbeats, receives zone commands, resolves targets to unit addresses/coils, builds CRC16-validated Modbus RTU frames (using FC15 optimization for grouped coils on the same slave and FC05 for single coils), reads responses from the serial RS485 port, and returns ACK loops.
Run: 

```bash
python3 -m venv path/to/venv.

pip3 install paho-mqtt pyserial followed by python3 master.py.

```
Modbus Slaves (ESP32): Located at 

slave.ino

Set up as a hardware UART RS485 Modbus RTU Server. Listens on RX2/TX2 pins, controls the transceiver's RE/DE transmit/receive pins dynamically, verifies CRC16, toggles physical GPIO pins mapping to relay coils (0-7), and returns response packets to the master.
Includes the complete MAX485 to ESP32 wiring schematic and pin mapping logs inside the code comments.


sudo apt update
sudo apt install -y python3-paho-mqtt python3-serial

pip3 install paho-mqtt pyserial --break-system-packages


# Create the virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install requirements inside the environment
pip install paho-mqtt pyserial

# Run the master script
python master.py
