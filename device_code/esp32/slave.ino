/**
 * ESP32 Drip Irrigation Modbus RTU Slave
 * 
 * This code turns an ESP32 into a Modbus RTU Slave Board (Server).
 * It listens on HardwareSerial2 connected to a MAX485/SP3485 transceiver,
 * parses Function Code 05 (Write Single Coil) and Function Code 15 (Write Multiple Coils),
 * toggles physical relay pins (Coils 0-7), and returns standard Modbus response frames.
 * 
 * Hardware Connections (MAX485 to ESP32):
 * - MAX485 RO (Receiver Output)   -> ESP32 RX2 (GPIO 16)
 * - MAX485 DI (Driver Input)      -> ESP32 TX2 (GPIO 17)
 * - MAX485 RE & DE (Tied together)-> ESP32 RE_DE Control Pin (GPIO 4)
 * - MAX485 VCC                    -> ESP32 3.3V or 5V (depending on transceiver model)
 * - MAX485 GND                    -> ESP32 GND
 */

#include <Arduino.h>

// --- Configuration ---
#define MODBUS_UNIT_ID 1  // Change to 2 or 3 for other slave boards!

// Pin Assignments
#define RE_DE_PIN 4      // DE and RE control pin for RS485 transceiver
#define RX2_PIN 16       // ESP32 RX2 Pin
#define TX2_PIN 17       // ESP32 TX2 Pin

// Relay Coil Mapping (8 Output Pins)
// Coils 0-7 map to these physical GPIO pins
const int coilPins[8] = {18, 19, 21, 22, 23, 25, 26, 27};

// Global Coil Register state array (0 = OFF/Closed, 1 = ON/Open)
byte coilRegisters[8] = {0, 0, 0, 0, 0, 0, 0, 0};

// --- Modbus RTU CRC16 Checksum Utility ---
uint16_t calculateCRC16(byte *data, int length) {
  uint16_t crc = 0xFFFF;
  for (int pos = 0; pos < length; pos++) {
    crc ^= data[pos];
    for (int i = 8; i != 0; i--) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xA001;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc;
}

// RS485 Helper Functions
void setTransmitMode() {
  digitalWrite(RE_DE_PIN, HIGH);
  delayMicroseconds(10); // Wait for transceiver to settle
}

void setReceiveMode() {
  delay(1); // Ensure last byte has completely left UART buffer
  digitalWrite(RE_DE_PIN, LOW);
}

void sendResponse(byte *frame, int length) {
  uint16_t crc = calculateCRC16(frame, length);
  setTransmitMode();
  
  // Send payload
  Serial2.write(frame, length);
  // Send CRC (Low byte first, then High byte)
  Serial2.write(crc & 0xFF);
  Serial2.write((crc >> 8) & 0xFF);
  
  Serial2.flush(); // Wait for completion of transmission
  setReceiveMode();
}

void operateRelay(int coilAddress, byte state) {
  if (coilAddress >= 0 && coilAddress < 8) {
    coilRegisters[coilAddress] = state;
    // Toggling the pin state (assuming active-high relays. Set LOW for active-low boards)
    digitalWrite(coilPins[coilAddress], state ? HIGH : LOW);
    
    Serial.print("[SLAVE] Relay ");
    Serial.print(coilAddress);
    Serial.println(state ? " -> ON" : " -> OFF");
  }
}

void setup() {
  // Start Debug Serial Monitor
  Serial.begin(115200);
  Serial.println("\n=======================================================");
  Serial.print("[SLAVE] ESP32 Modbus RTU Board. Unit ID: ");
  Serial.println(MODBUS_UNIT_ID);
  Serial.println("=======================================================");

  // Initialize RE/DE control pin
  pinMode(RE_DE_PIN, OUTPUT);
  setReceiveMode();

  // Initialize physical relay pins as outputs
  for (int i = 0; i < 8; i++) {
    pinMode(coilPins[i], OUTPUT);
    digitalWrite(coilPins[i], LOW); // Ensure relays start turned OFF
  }

  // Start Hardware Serial2 (RS485 interface)
  // 9600 baud, 8 data bits, no parity, 1 stop bit (SERIAL_8N1)
  Serial2.begin(9600, SERIAL_8N1, RX2_PIN, TX2_PIN);
  Serial.println("[SLAVE] Listening on RS485 bus...");
}

void loop() {
  static byte rxBuffer[256];
  static int rxLength = 0;
  static unsigned long lastByteTime = 0;

  // Check if bytes are arriving
  if (Serial2.available() > 0) {
    if (rxLength < 256) {
      rxBuffer[rxLength++] = Serial2.read();
      lastByteTime = millis();
    } else {
      Serial2.read(); // Clear overflow bytes
    }
  }

  // Modbus frames are separated by a quiet silence gap of at least 3.5 character times.
  // At 9600 baud, this is ~4ms. We will use a 10ms threshold to process a completed packet.
  if (rxLength > 0 && (millis() - lastByteTime > 10)) {
    
    // Check if the frame starts with our Unit ID
    if (rxBuffer[0] == MODBUS_UNIT_ID && rxLength >= 5) {
      
      // Extract received CRC (last 2 bytes)
      uint16_t rxCrc = rxBuffer[rxLength - 2] | (rxBuffer[rxLength - 1] << 8);
      
      // Calculate CRC of the payload
      uint16_t calCrc = calculateCRC16(rxBuffer, rxLength - 2);
      
      if (rxCrc == calCrc) {
        byte fc = rxBuffer[1];
        Serial.print("[SLAVE] Valid Frame. FC: ");
        Serial.println(fc);

        // --- Handle Function Code 05: Write Single Coil ---
        if (fc == 5 && rxLength == 8) {
          uint16_t coilAddress = (rxBuffer[2] << 8) | rxBuffer[3];
          uint16_t actionValue = (rxBuffer[4] << 8) | rxBuffer[5];
          
          byte state = (actionValue == 0xFF00) ? 1 : 0;
          operateRelay(coilAddress, state);

          // Return Echo response (first 6 bytes of the command)
          byte response[6];
          memcpy(response, rxBuffer, 6);
          sendResponse(response, 6);
        }
        
        // --- Handle Function Code 15 (0x0F): Write Multiple Coils ---
        else if (fc == 15 && rxLength >= 9) {
          uint16_t startAddress = (rxBuffer[2] << 8) | rxBuffer[3];
          uint16_t quantity = (rxBuffer[4] << 8) | rxBuffer[5];
          byte byteCount = rxBuffer[6];
          
          // Verify bounds
          if (rxLength == (9 + byteCount)) {
            for (int i = 0; i < quantity; i++) {
              int currentCoil = startAddress + i;
              byte targetByte = rxBuffer[7 + (i / 8)];
              byte state = (targetByte >> (i % 8)) & 1;
              operateRelay(currentCoil, state);
            }

            // Return ACK Response: [Unit ID, 15, Start Address (2), Quantity (2)]
            byte response[6];
            response[0] = MODBUS_UNIT_ID;
            response[1] = 15;
            response[2] = rxBuffer[2];
            response[3] = rxBuffer[3];
            response[4] = rxBuffer[4];
            response[5] = rxBuffer[5];
            sendResponse(response, 6);
          }
        }
        else {
          Serial.println("[SLAVE] Unsupported Function Code or size mismatch.");
        }
      } else {
        Serial.println("[SLAVE] Checksum/CRC error. Frame ignored.");
      }
    }
    
    // Clear buffer for the next transaction
    rxLength = 0;
  }
}
