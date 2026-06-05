class Valve {
  final String id;
  final String zoneId;
  final String deviceUid;
  final String name;
  final int valveNumber;
  final String status; // open, closed, unknown, error, disabled
  final DateTime? lastStatusAt;
  final DateTime? installedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Valve({
    required this.id,
    required this.zoneId,
    required this.deviceUid,
    required this.name,
    required this.valveNumber,
    required this.status,
    this.lastStatusAt,
    this.installedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Valve.fromJson(Map<String, dynamic> j) {
    return Valve(
      id: j['id'].toString(),
      zoneId: j['zoneId'].toString(),
      deviceUid: j['deviceUid'] as String? ?? '',
      name: j['name'] as String? ?? '',
      valveNumber: j['valveNumber'] as int? ?? 1,
      status: j['status'] as String? ?? 'unknown',
      lastStatusAt: j['lastStatusAt'] != null ? DateTime.tryParse(j['lastStatusAt'].toString()) : null,
      installedAt: j['installedAt'] != null ? DateTime.tryParse(j['installedAt'].toString()) : null,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'zoneId': zoneId,
        'deviceUid': deviceUid,
        'name': name,
        'valveNumber': valveNumber,
        'status': status,
        'lastStatusAt': lastStatusAt?.toIso8601String(),
        'installedAt': installedAt?.toIso8601String(),
      };

  Valve copyWith({
    String? id,
    String? zoneId,
    String? deviceUid,
    String? name,
    int? valveNumber,
    String? status,
    DateTime? lastStatusAt,
    DateTime? installedAt,
  }) {
    return Valve(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      deviceUid: deviceUid ?? this.deviceUid,
      name: name ?? this.name,
      valveNumber: valveNumber ?? this.valveNumber,
      status: status ?? this.status,
      lastStatusAt: lastStatusAt ?? this.lastStatusAt,
      installedAt: installedAt ?? this.installedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
