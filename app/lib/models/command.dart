class CommandItem {
  final String id;
  final String commandId;
  final String valveId;
  final String? valveName;
  final int sequenceNumber;
  final String action; // open, close
  final String status; // pending, sent, acknowledged, failed, timeout, skipped
  final DateTime? sentAt;
  final DateTime? acknowledgedAt;
  final String? failedReason;

  const CommandItem({
    required this.id,
    required this.commandId,
    required this.valveId,
    this.valveName,
    required this.sequenceNumber,
    required this.action,
    required this.status,
    this.sentAt,
    this.acknowledgedAt,
    this.failedReason,
  });

  factory CommandItem.fromJson(Map<String, dynamic> json) {
    return CommandItem(
      id: json['id']?.toString() ?? '',
      commandId: json['commandId']?.toString() ?? '',
      valveId: json['valveId']?.toString() ?? '',
      valveName: json['valveName'] as String? ?? (json['valve'] != null ? json['valve']['name'] as String? : null),
      sequenceNumber: json['sequenceNumber'] as int? ?? 0,
      action: json['action'] as String? ?? 'open',
      status: json['status'] as String? ?? 'pending',
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'].toString()) : null,
      acknowledgedAt: json['acknowledgedAt'] != null ? DateTime.tryParse(json['acknowledgedAt'].toString()) : null,
      failedReason: json['failedReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'commandId': commandId,
    'valveId': valveId,
    'valveName': valveName,
    'sequenceNumber': sequenceNumber,
    'action': action,
    'status': status,
    'sentAt': sentAt?.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'failedReason': failedReason,
  };
}

class Command {
  final String id;
  final String commandUid;
  final String farmerId;
  final String fieldId;
  final String masterControllerId;
  final String requestedByUserId;
  final String targetType; // valve, zone, field
  final String targetId;
  final String action; // open, close
  final String status; // created, queued, sent, partialSuccess, acknowledged, failed, timeout, expired
  final String source; // app, adminPanel, schedule, support, deviceHttp
  final int retryCount;
  final int maxRetries;
  final DateTime? expiresAt;
  final DateTime? sentAt;
  final DateTime? acknowledgedAt;
  final String? failedReason;
  final List<CommandItem> commandItems;
  final DateTime createdAt;

  const Command({
    required this.id,
    required this.commandUid,
    required this.farmerId,
    required this.fieldId,
    required this.masterControllerId,
    required this.requestedByUserId,
    required this.targetType,
    required this.targetId,
    required this.action,
    required this.status,
    required this.source,
    required this.retryCount,
    required this.maxRetries,
    this.expiresAt,
    this.sentAt,
    this.acknowledgedAt,
    this.failedReason,
    this.commandItems = const [],
    required this.createdAt,
  });

  factory Command.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => CommandItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        (json['commandItems'] as List<dynamic>?)
            ?.map((e) => CommandItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return Command(
      id: json['id']?.toString() ?? '',
      commandUid: json['commandUid'] as String? ?? '',
      farmerId: json['farmerId']?.toString() ?? '',
      fieldId: json['fieldId']?.toString() ?? '',
      masterControllerId: json['masterControllerId']?.toString() ?? '',
      requestedByUserId: json['requestedByUserId']?.toString() ?? '',
      targetType: json['targetType'] as String? ?? 'valve',
      targetId: json['targetId']?.toString() ?? '',
      action: json['action'] as String? ?? 'open',
      status: json['status'] as String? ?? 'created',
      source: json['source'] as String? ?? 'app',
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'].toString()) : null,
      acknowledgedAt: json['acknowledgedAt'] != null ? DateTime.tryParse(json['acknowledgedAt'].toString()) : null,
      failedReason: json['failedReason'] as String?,
      commandItems: itemsList,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'commandUid': commandUid,
    'farmerId': farmerId,
    'fieldId': fieldId,
    'masterControllerId': masterControllerId,
    'requestedByUserId': requestedByUserId,
    'targetType': targetType,
    'targetId': targetId,
    'action': action,
    'status': status,
    'source': source,
    'retryCount': retryCount,
    'maxRetries': maxRetries,
    'expiresAt': expiresAt?.toIso8601String(),
    'sentAt': sentAt?.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'failedReason': failedReason,
    'commandItems': commandItems.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  bool get isActive => !['acknowledged', 'failed', 'timeout', 'expired', 'partialSuccess'].contains(status);
}
