import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/env.dart';
import '../models/api_device.dart';

const String _wsUrl = Env.wsBaseUrl;

typedef TelemetryCallback = void Function(String deviceId, TelemetryRow row);
typedef MasterHeartbeatCallback = void Function(String mcId, Map<String, dynamic> data);
typedef ValveStatusCallback = void Function(Map<String, dynamic> data);

/// Singleton WebSocket service for real-time telemetry.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  final _listeners = <TelemetryCallback>[];
  final _masterHeartbeatListeners = <MasterHeartbeatCallback>[];
  final _valveStatusListeners = <ValveStatusCallback>[];

  bool get connected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null) return; // already initialised
    _socket = io.io(
      _wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/ws') // must match backend: path: '/ws'
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[socket] connected');
      // Subscribe to the all-devices feed so the dashboard receives every
      // device:telemetry event broadcast by the MQTT ingestion job.
      _socket!.emit('subscribe:all-devices');
    });

    _socket!.onDisconnect((_) => debugPrint('[socket] disconnected'));

    _socket!.onConnectError((e) => debugPrint('[socket] connect error: $e'));

    // ── all-devices dashboard feed ──────────────────────────────────────────
    // Backend: io.to('all-devices').emit('device:telemetry', { deviceId, row })
    _socket!.on('device:telemetry', (data) {
      if (data is! Map) return;
      final deviceId = data['deviceId']?.toString() ?? '';
      final rawRow = data['row'];
      if (rawRow is! Map) return;
      final row = TelemetryRow.fromJson(Map<String, dynamic>.from(rawRow));
      for (final cb in List.of(_listeners)) {
        cb(deviceId, row);
      }
    });

    // ── per-device room feed ────────────────────────────────────────────────
    // Backend: io.to('device:$id').emit('telemetry', row)
    _socket!.on('telemetry', (data) {
      if (data is! Map) return;
      // When coming from a device room, deviceId may be embedded or inferred
      final deviceId = data['deviceId']?.toString() ?? '';
      final row = TelemetryRow.fromJson(Map<String, dynamic>.from(data));
      for (final cb in List.of(_listeners)) {
        cb(deviceId, row);
      }
    });

    // ── master heartbeats and statuses ──────────────────────────────────────
    _socket!.on('masterHeartbeat', (data) {
      if (data is! Map) return;
      final mcId = data['masterControllerId']?.toString() ?? '';
      for (final cb in List.of(_masterHeartbeatListeners)) {
        cb(mcId, Map<String, dynamic>.from(data));
      }
    });

    // ── valve status updates ────────────────────────────────────────────────
    _socket!.on('valveStatusUpdated', (data) {
      if (data is! Map) return;
      for (final cb in List.of(_valveStatusListeners)) {
        cb(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _listeners.clear();
    _masterHeartbeatListeners.clear();
    _valveStatusListeners.clear();
  }

  /// Subscribe to updates for a single device room.
  void subscribeDevice(String deviceId) {
    _socket?.emit('subscribe:device', deviceId);
  }

  void unsubscribeDevice(String deviceId) {
    _socket?.emit('unsubscribe:device', deviceId);
  }

  void joinField(String fieldId) {
    _socket?.emit('joinField', fieldId);
  }

  void addListener(TelemetryCallback cb) => _listeners.add(cb);
  void removeListener(TelemetryCallback cb) => _listeners.remove(cb);

  void addMasterHeartbeatListener(MasterHeartbeatCallback cb) => _masterHeartbeatListeners.add(cb);
  void removeMasterHeartbeatListener(MasterHeartbeatCallback cb) => _masterHeartbeatListeners.remove(cb);

  void addValveStatusListener(ValveStatusCallback cb) => _valveStatusListeners.add(cb);
  void removeValveStatusListener(ValveStatusCallback cb) => _valveStatusListeners.remove(cb);
}
