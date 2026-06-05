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
  };

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
}
