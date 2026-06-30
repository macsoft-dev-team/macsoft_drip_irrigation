/// Device as returned by the backend REST API.
class ApiDevice {
  final String id;
  final String imeinumber;
  final String? name;
  final bool isActive;
  final String? userId;
  final ApiDeviceUser? user;
  final List<TelemetryRow> telemetryLogs;
  final String? mqttCmdTopic;
  final Map<String, dynamic>? config;

  const ApiDevice({
    required this.id,
    required this.imeinumber,
    this.name,
    required this.isActive,
    this.userId,
    this.user,
    this.telemetryLogs = const [],
    this.mqttCmdTopic,
    this.config,
  });

  factory ApiDevice.fromJson(Map<String, dynamic> j) {
    final logs =
        (j['telemetryLogs'] as List<dynamic>?)
            ?.map((e) => TelemetryRow.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ApiDevice(
      id: j['id'].toString(),
      imeinumber: j['imeinumber']?.toString() ?? '',
      name: j['name'] as String?,
      isActive: j['isActive'] as bool? ?? false,
      userId: j['userId']?.toString(),
      user: j['user'] != null
          ? ApiDeviceUser.fromJson(j['user'] as Map<String, dynamic>)
          : null,
      telemetryLogs: logs,
      mqttCmdTopic: j['mqttCmdTopic'] as String?,
      config: j['config'] as Map<String, dynamic>?,
    );
  }

  ApiDevice copyWith({
    bool? isActive,
    List<TelemetryRow>? telemetryLogs,
    String? name,
    String? userId,
    ApiDeviceUser? user,
    Map<String, dynamic>? config,
  }) {
    return ApiDevice(
      id: id,
      imeinumber: imeinumber,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      telemetryLogs: telemetryLogs ?? this.telemetryLogs,
      mqttCmdTopic: mqttCmdTopic,
      config: config ?? this.config,
    );
  }

  DateTime? get lastHeartbeat =>
      telemetryLogs.isNotEmpty ? telemetryLogs.first.time : null;
}

class ApiDeviceUser {
  final String id;
  final String? name;
  final String? email;

  const ApiDeviceUser({required this.id, this.name, this.email});

  factory ApiDeviceUser.fromJson(Map<String, dynamic> j) => ApiDeviceUser(
    id: j['id'].toString(),
    name: j['name'] as String?,
    email: j['email'] as String?,
  );

  String get displayName => name ?? email ?? id;
}

/// A single telemetry reading row from the backend.
class TelemetryRow {
  final DateTime? time;
  final double? iv1, iv2, iv3; // voltages
  final double? ic1, ic2, ic3; // currents
  final dynamic flc, sts, amm, phm, ohr, shr, chr;
  final double? rsi; // signal strength
  final Map<String, dynamic>? payload; // raw JSON as received from device
  final double? moistureLevel;
  final int? batteryLevel;
  final int? signalStrength;
  final double? temperature;
  final double? humidity;

  const TelemetryRow({
    this.time,
    this.iv1,
    this.iv2,
    this.iv3,
    this.ic1,
    this.ic2,
    this.ic3,
    this.flc,
    this.sts,
    this.amm,
    this.phm,
    this.ohr,
    this.shr,
    this.chr,
    this.rsi,
    this.payload,
    this.moistureLevel,
    this.batteryLevel,
    this.signalStrength,
    this.temperature,
    this.humidity,
  });

  factory TelemetryRow.fromJson(Map<String, dynamic> j) {
    DateTime? t;
    if (j['time'] != null) {
      t = DateTime.tryParse(j['time'].toString());
    }
    return TelemetryRow(
      time: t,
      iv1: _toDouble(j['iv1']),
      iv2: _toDouble(j['iv2']),
      iv3: _toDouble(j['iv3']),
      ic1: _toDouble(j['ic1']),
      ic2: _toDouble(j['ic2']),
      ic3: _toDouble(j['ic3']),
      flc: j['flc'],
      sts: j['sts'],
      amm: j['amm'],
      phm: j['phm'],
      ohr: j['ohr'],
      shr: j['shr'],
      chr: j['chr'],
      rsi: _toDouble(j['rsi']),
      payload: j['payload'] as Map<String, dynamic>?,
      moistureLevel: _toDouble(j['moistureLevel']),
      batteryLevel: j['batteryLevel'] != null ? (j['batteryLevel'] as num).toInt() : null,
      signalStrength: j['signalStrength'] != null ? (j['signalStrength'] as num).toInt() : null,
      temperature: _toDouble(j['temperature']),
      humidity: _toDouble(j['humidity']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }
}

/// A command log entry.
class DeviceCommand {
  final String id;
  final Map<String, dynamic> payload;
  final String status; // PENDING | SENT | ACK | FAILED
  final DateTime? createdAt;

  const DeviceCommand({
    required this.id,
    required this.payload,
    required this.status,
    this.createdAt,
  });

  factory DeviceCommand.fromJson(Map<String, dynamic> j) => DeviceCommand(
    id: j['id'].toString(),
    payload: (j['payload'] as Map<String, dynamic>?) ?? {},
    status: j['status']?.toString() ?? 'PENDING',
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'].toString())
        : null,
  );
}
