# Curl examples

## Login

```bash
TOKEN=$(curl -s http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"8888888888","password":"farmer12345"}' | jq -r '.data.token')
```

## Send heartbeat to mark master online

```bash
curl -X POST http://localhost:4000/api/v1/device/masters/master-demo-001/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"firmwareVersion":"1.0.0","signalStrength":80,"batteryVoltage":12.5,"powerSource":"solar"}'
```

## Open valve

```bash
curl -X POST http://localhost:4000/api/v1/commands/valves/1/open \
  -H "Authorization: Bearer $TOKEN"
```

## ACK command

Replace `<commandUid>` with the UID from the open-valve response.

```bash
curl -X POST http://localhost:4000/api/v1/device/masters/master-demo-001/ack \
  -H "Content-Type: application/json" \
  -d '{
    "commandUid":"<commandUid>",
    "status":"acknowledged",
    "items":[
      {"valveId":"1","status":"acknowledged","currentValveStatus":"open"}
    ]
  }'
```
