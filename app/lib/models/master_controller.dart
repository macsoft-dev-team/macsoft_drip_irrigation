class MasterController {
  final String id;
  final String fieldId;
  final String deviceUid;
  final String? imei;
  final String? simNumber;
  final String? firmwareVersion;
  final String connectionType; // gsm4g, gsm5g, wifi, loraGateway
  final String status; // online, offline, error, disabled
  final DateTime? lastHeartbeatAt;
  final String? lastIp;
  final DateTime? installedAt;

  const MasterController({
    required this.id,
    required this.fieldId,
    required this.deviceUid,
    this.imei,
    this.simNumber,
    this.firmwareVersion,
    required this.connectionType,
    required this.status,
    this.lastHeartbeatAt,
    this.lastIp,
    this.installedAt,
  });

  factory MasterController.fromJson(Map<String, dynamic> json) {
    return MasterController(
      id: json['id']?.toString() ?? '',
      fieldId: json['fieldId']?.toString() ?? '',
      deviceUid: json['deviceUid'] as String? ?? '',
      imei: json['imei'] as String?,
      simNumber: json['simNumber'] as String?,
      firmwareVersion: json['firmwareVersion'] as String?,
      connectionType: json['connectionType'] as String? ?? 'gsm4g',
      status: json['status'] as String? ?? 'offline',
      lastHeartbeatAt: json['lastHeartbeatAt'] != null ? DateTime.tryParse(json['lastHeartbeatAt'].toString()) : null,
      lastIp: json['lastIp'] as String?,
      installedAt: json['installedAt'] != null ? DateTime.tryParse(json['installedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fieldId': fieldId,
    'deviceUid': deviceUid,
    'imei': imei,
    'simNumber': simNumber,
    'firmwareVersion': firmwareVersion,
    'connectionType': connectionType,
    'status': status,
    'lastHeartbeatAt': lastHeartbeatAt?.toIso8601String(),
    'lastIp': lastIp,
    'installedAt': installedAt?.toIso8601String(),
  };

  bool get isOnline => status == 'online';
}
