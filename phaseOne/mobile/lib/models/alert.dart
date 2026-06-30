enum AlertSeverity { info, warning, critical }

class Alert {
  final String id;
  final String title;
  final String message;
  final String type; // masterOffline, commandFailed, valveError, scheduleFailed, maintenanceReminder, orderUpdate
  final AlertSeverity severity;
  final DateTime createdAt;
  final bool isRead;

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.createdAt,
    required this.isRead,
  });

  factory Alert.fromJson(Map<String, dynamic> j) {
    AlertSeverity parseSeverity(String? s) {
      switch ((s ?? '').toLowerCase()) {
        case 'warning':
          return AlertSeverity.warning;
        case 'critical':
        case 'error':
          return AlertSeverity.critical;
        case 'info':
        default:
          return AlertSeverity.info;
      }
    }

    return Alert(
      id: j['id']?.toString() ?? '',
      title: j['title'] as String? ?? 'Alert',
      message: j['message'] as String? ?? '',
      type: j['type'] as String? ?? 'info',
      severity: parseSeverity(j['severity'] as String?),
      createdAt: j['createdAt'] != null ? DateTime.parse(j['createdAt'].toString()) : DateTime.now(),
      isRead: j['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'severity': severity.name,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  Alert copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    AlertSeverity? severity,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
