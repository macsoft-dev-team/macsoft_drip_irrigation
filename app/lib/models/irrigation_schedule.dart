import 'dart:convert';

class IrrigationSchedule {
  final String id;
  final String farmerId;
  final String fieldId;
  final String name;
  final String targetType; // valve, zone
  final String targetId;
  final String? targetName;
  final String action; // openThenClose
  final String startTime; // HH:mm
  final int durationMinutes;
  final String repeatType; // once, daily, weekly, customDays
  final List<String> repeatDays; // e.g. ["monday", "tuesday"] or ["1", "2"]
  final String status; // active, paused, deleted
  final String scheduleType; // timeBased, timerBased
  final List<String>? zoneIds;

  const IrrigationSchedule({
    required this.id,
    required this.farmerId,
    required this.fieldId,
    required this.name,
    required this.targetType,
    required this.targetId,
    this.targetName,
    required this.action,
    required this.startTime,
    required this.durationMinutes,
    required this.repeatType,
    required this.repeatDays,
    required this.status,
    required this.scheduleType,
    this.zoneIds,
  });

  factory IrrigationSchedule.fromJson(Map<String, dynamic> json) {
    List<String> days = [];
    if (json['repeatDays'] != null) {
      try {
        if (json['repeatDays'] is String) {
          final decoded = jsonDecode(json['repeatDays'] as String);
          if (decoded is List) {
            days = decoded.map((e) => e.toString()).toList();
          }
        } else if (json['repeatDays'] is List) {
          days = (json['repeatDays'] as List).map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    List<String>? parsedZoneIds;
    if (json['zoneIds'] != null) {
      try {
        if (json['zoneIds'] is String) {
          final decoded = jsonDecode(json['zoneIds'] as String);
          if (decoded is List) {
            parsedZoneIds = decoded.map((e) => e.toString()).toList();
          }
        } else if (json['zoneIds'] is List) {
          parsedZoneIds = (json['zoneIds'] as List).map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return IrrigationSchedule(
      id: json['id']?.toString() ?? '',
      farmerId: json['farmerId']?.toString() ?? '',
      fieldId: json['fieldId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      targetType: json['targetType'] as String? ?? 'zone',
      targetId: json['targetId']?.toString() ?? '',
      targetName: json['targetName'] as String?,
      action: json['action'] as String? ?? 'openThenClose',
      startTime: json['startTime'] as String? ?? '06:00',
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      repeatType: json['repeatType'] as String? ?? 'daily',
      repeatDays: days,
      status: json['status'] as String? ?? 'active',
      scheduleType: json['scheduleType'] as String? ?? 'timeBased',
      zoneIds: parsedZoneIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmerId': farmerId,
    'fieldId': fieldId,
    'name': name,
    'targetType': targetType,
    'targetId': targetId,
    'targetName': targetName,
    'action': action,
    'startTime': startTime,
    'durationMinutes': durationMinutes,
    'repeatType': repeatType,
    'repeatDays': repeatDays,
    'status': status,
    'scheduleType': scheduleType,
    'zoneIds': zoneIds,
  };

  IrrigationSchedule copyWith({
    String? id,
    String? farmerId,
    String? fieldId,
    String? name,
    String? targetType,
    String? targetId,
    String? targetName,
    String? action,
    String? startTime,
    int? durationMinutes,
    String? repeatType,
    List<String>? repeatDays,
    String? status,
    String? scheduleType,
    List<String>? zoneIds,
  }) {
    return IrrigationSchedule(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      fieldId: fieldId ?? this.fieldId,
      name: name ?? this.name,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      action: action ?? this.action,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      status: status ?? this.status,
      scheduleType: scheduleType ?? this.scheduleType,
      zoneIds: zoneIds ?? this.zoneIds,
    );
  }

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
}
