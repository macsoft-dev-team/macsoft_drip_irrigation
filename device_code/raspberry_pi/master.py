#!/usr/bin/env python3
import json
import logging
import time
import serial
import threading
import paho.mqtt.client as mqtt

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

# --- Configuration ---
MQTT_BROKER = "mqtt.macsoftautomations.in"  # Update with your cloud/local broker IP
MQTT_PORT = 1883
MQTT_USER = "drip_admin"
MQTT_PASSWORD = "admin"
DEVICE_UID = "MASTER-001"
FARM_ID = "1"
FIELD_ID = "1"

# RS485 Serial Port Configuration
SERIAL_PORT = "/dev/ttyS0"  # GPIO serial port on Raspberry Pi (use /dev/ttyUSB0 if USB-to-RS485 adapter is used)
BAUD_RATE = 9600
SERIAL_TIMEOUT = 1.0  # seconds

# Topics
COMMAND_TOPIC = f"farm/{FARM_ID}/field/{FIELD_ID}/master/{DEVICE_UID}/command"
ACK_TOPIC = f"farm/{FARM_ID}/field/{FIELD_ID}/master/{DEVICE_UID}/ack"
STATUS_TOPIC = f"farm/{FARM_ID}/field/{FIELD_ID}/master/{DEVICE_UID}/status"
HEARTBEAT_TOPIC = f"farm/{FARM_ID}/field/{FIELD_ID}/master/{DEVICE_UID}/heartbeat"

# Initialize Serial Port
try:
    ser = serial.Serial(
        port=SERIAL_PORT,
        baudrate=BAUD_RATE,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        bytesize=serial.EIGHTBITS,
        timeout=SERIAL_TIMEOUT
    )
    logging.info(f"RS485 Serial Port initialized on {SERIAL_PORT} @ {BAUD_RATE} baud")
except Exception as e:
    logging.error(f"Failed to open serial port {SERIAL_PORT}: {e}")
    ser = None

# --- Modbus RTU Utilities ---
def calculate_crc16(data: bytes) -> bytes:
    """Calculates Modbus RTU CRC16 checksum (low byte first, then high byte)."""
    crc = 0xFFFF
    for pos in data:
        crc ^= pos
        for _ in range(8):
            if (crc & 1) != 0:
                crc = (crc >> 1) ^ 0xA001;
            else:
                crc >>= 1
    # Returns 2 bytes: Low byte, High byte
    return bytes([crc & 0xFF, (crc >> 8) & 0xFF])

def send_modbus_frame(frame: bytes) -> bytes:
    """Sends a raw Modbus frame over RS485 and waits for a response."""
    if not ser:
        logging.error("Serial port is not available")
        return b""
    
    # Flush buffers
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    
    # Transmit frame
    logging.info(f"RS485 Tx -> [ {frame.hex().upper()} ]")
    ser.write(frame)
    ser.flush()  # Ensure data is transmitted
    
    # Read response (Unit ID + FC + payload details + 2 bytes CRC)
    # Most Modbus RTU responses are at least 5-8 bytes.
    # We will read dynamically until timeout.
    response = ser.read(256)
    if response:
        logging.info(f"RS485 Rx <- [ {response.hex().upper()} ]")
    else:
        logging.warning("RS485 Rx <- Timeout (No response from Slave)")
    
    return response

def verify_modbus_response(response: bytes, expected_unit_id: int, expected_fc: int) -> bool:
    """Validates the Unit ID, Function Code, and CRC16 checksum of a Modbus response."""
    if len(response) < 5:
        return False
        
    unit_id = response[0]
    fc = response[1]
    
    if unit_id != expected_unit_id or fc != expected_fc:
        logging.warning(f"Modbus response mismatch. Expected Unit: {expected_unit_id}, FC: {expected_fc}. Got Unit: {unit_id}, FC: {fc}")
        return False
        
    # Check CRC
    payload = response[:-2]
    rx_crc = response[-2:]
    cal_crc = calculate_crc16(payload)
    
    if rx_crc != cal_crc:
        logging.warning("Modbus response CRC verification failed!")
        return False
        
    return True

# --- Modbus Frame Builders ---
def build_fc05_frame(unit_id: int, coil_address: int, turn_on: bool) -> bytes:
    """Builds a Modbus Function Code 05 (Write Single Coil) RTU frame."""
    value = 0xFF00 if turn_on else 0x0000
    frame = bytes([
        unit_id,
        5,  # FC 05
        (coil_address >> 8) & 0xFF,  # Address High
        coil_address & 0xFF,         # Address Low
        (value >> 8) & 0xFF,         # Value High
        value & 0xFF                 # Value Low
    ])
    crc = calculate_crc16(frame)
    return frame + crc

def build_fc15_frame(unit_id: int, start_address: int, quantity: int, values: list) -> bytes:
    """Builds a Modbus Function Code 15 (Write Multiple Coils) RTU frame."""
    byte_count = (quantity + 7) // 8
    value_bytes = bytearray(byte_count)
    
    for i, val in enumerate(values):
        if val:
            byte_idx = i // 8
            bit_idx = i % 8
            value_bytes[byte_idx] |= (1 << bit_idx)
            
    frame = bytes([
        unit_id,
        15,  # FC 15 (0x0F)
        (start_address >> 8) & 0xFF,  # Start Address High
        start_address & 0xFF,         # Start Address Low
        (quantity >> 8) & 0xFF,       # Quantity High
        quantity & 0xFF,              # Quantity Low
        byte_count                    # Byte Count
    ]) + bytes(value_bytes)
    
    crc = calculate_crc16(frame)
    return frame + crc

# --- MQTT Handlers ---
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        logging.info(f"Connected to MQTT Broker successfully.")
        client.subscribe(COMMAND_TOPIC, qos=1)
        logging.info(f"Subscribed to command topic: {COMMAND_TOPIC}")
    else:
        logging.error(f"Connection failed with code {rc}")

def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        command_uid = payload.get("commandUid")
        target_type = payload.get("targetType")
        action = payload.get("action")
        valves = payload.get("valves", [])
        
        logging.info(f"Command Received: {target_type} -> {action} (UID: {command_uid})")
        
        if target_type == "motor":
            # Onboard relay implementation: toggle Pi GPIO pin or onboard controller output
            logging.info(f"Executing onboard motor relay command: {action}")
            # Mock success ACK
            send_mqtt_ack(client, command_uid, "acknowledged", [])
            return
            
        if not valves:
            logging.warning("Valves list is empty in the payload")
            send_mqtt_ack(client, command_uid, "failed", [], "Valves list empty")
            return
            
        # Group valves by Modbus Address (Unit ID)
        groups = {}
        for v in valves:
            unit_id = int(v["modbusAddress"])
            if unit_id not in groups:
                groups[unit_id] = []
            groups[unit_id].append(v)
            
        valve_results = []
        is_partial = False
        all_success = True
        
        turn_on = (action == "open")
        
        for unit_id, group_valves in groups.items():
            logging.info(f"Processing Modbus Unit ID {unit_id} ({len(group_valves)} valves)")
            
            success = False
            
            # Optimization: If more than 1 coil to toggle, use FC 15. Otherwise, use FC 05.
            if len(group_valves) > 1:
                coil_addresses = [int(v["coilAddress"]) for v in group_valves]
                min_coil = min(coil_addresses)
                max_coil = max(coil_addresses)
                qty = max_coil - min_coil + 1
                
                # Build values array (1 for ON, 0 for OFF)
                # Keep other coils as 0 for simplicity, or implement caching if reading states is supported
                coils_values = [0] * qty
                for v in group_valves:
                    coils_values[int(v["coilAddress"]) - min_coil] = 1 if turn_on else 0
                    
                frame = build_fc15_frame(unit_id, min_coil, qty, coils_values)
                response = send_modbus_frame(frame)
                success = verify_modbus_response(response, unit_id, 15)
            else:
                valve = group_valves[0]
                coil = int(valve["coilAddress"])
                frame = build_fc05_frame(unit_id, coil, turn_on)
                response = send_modbus_frame(frame)
                success = verify_modbus_response(response, unit_id, 5)
                
            for v in group_valves:
                valve_results.append({
                    "valveId": v["valveId"],
                    "status": "acknowledged" if success else "failed",
                    "currentValveStatus": "open" if (success and turn_on) else "closed" if (success and not turn_on) else "unknown",
                    "failedReason": None if success else "Modbus timeout or checksum error"
                })
                
            if success:
                is_partial = True
            else:
                all_success = False
                
        # Determine overall status
        overall_status = "acknowledged" if all_success else "partialSuccess" if is_partial else "failed"
        send_mqtt_ack(client, command_uid, overall_status, valve_results)
        
        # Publish real-time status dump
        publish_status_dump(client, valve_results)
        
    except Exception as e:
        logging.error(f"Error processing command message: {e}", exc_info=True)

def send_mqtt_ack(client, command_uid, status, items, failed_reason=None):
    payload = {
        "commandUid": command_uid,
        "status": status,
        "items": items
    }
    if failed_reason:
        payload["failedReason"] = failed_reason
        
    client.publish(ACK_TOPIC, json.dumps(payload), qos=1)
    logging.info(f"Published ACK response ({status}) to topic {ACK_TOPIC}")

def publish_status_dump(client, items):
    payload = {
        "valves": [
            {
                "valveId": item["valveId"],
                "currentValveStatus": item["currentValveStatus"]
            } for item in items if item["status"] == "acknowledged"
        ]
    }
    if payload["valves"]:
        client.publish(STATUS_TOPIC, json.dumps(payload), qos=1)
        logging.info(f"Published status dump to topic {STATUS_TOPIC}")

def heartbeat_loop(client):
    """Background loop sending heartbeats every 15 seconds to report status and keep master marked online."""
    while True:
        try:
            payload = {
                "firmwareVersion": "1.0.0",
                "signalStrength": 28,
                "batteryVoltage": 12.5,
                "powerSource": "mainPower",
                "tankLevel": 78,
                "motorStatus": "off"
            }
            client.publish(HEARTBEAT_TOPIC, json.dumps(payload))
            logging.info("Heartbeat published")
        except Exception as e:
            logging.error(f"Error in heartbeat thread: {e}")
        time.sleep(15)

# --- Main Runtime ---
def main():
    client = mqtt.Client()
    if MQTT_USER and MQTT_PASSWORD:
        client.username_pw_set(MQTT_USER, MQTT_PASSWORD)
        
    client.on_connect = on_connect
    client.on_message = on_message
    
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    except Exception as e:
        logging.error(f"Failed to connect to MQTT broker: {e}")
        return
        
    # Start heartbeat daemon thread
    t = threading.Thread(target=heartbeat_loop, args=(client,), daemon=True)
    t.start()
    
    # Block and process MQTT messages
    logging.info("Starting MQTT loop. Press Ctrl+C to exit.")
    try:
        client.loop_forever()
    except KeyboardInterrupt:
        logging.info("Exiting...")
    finally:
        if ser:
            ser.close()

if __name__ == "__main__":
    main()
