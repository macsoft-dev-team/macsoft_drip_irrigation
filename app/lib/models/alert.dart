class Alert {
  final String id;
  final String deviceId;
  final String deviceName;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isRead;

  const Alert({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.isRead,
  });
}

enum AlertSeverity { info, warning, critical }
