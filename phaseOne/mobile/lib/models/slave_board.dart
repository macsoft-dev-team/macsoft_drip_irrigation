class SlaveBoard {
  final String id;
  final String masterControllerId;
  final String deviceUid;
  final String name;
  final int modbusAddress;
  final String status; // active, inactive
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SlaveBoard({
    required this.id,
    required this.masterControllerId,
    required this.deviceUid,
    required this.name,
    required this.modbusAddress,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SlaveBoard.fromJson(Map<String, dynamic> j) {
    return SlaveBoard(
      id: j['id'].toString(),
      masterControllerId: j['masterControllerId'].toString(),
      deviceUid: j['deviceUid'] as String? ?? '',
      name: j['name'] as String? ?? '',
      modbusAddress: j['modbusAddress'] as int? ?? 1,
      status: j['status'] as String? ?? 'active',
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'masterControllerId': masterControllerId,
        'deviceUid': deviceUid,
        'name': name,
        'modbusAddress': modbusAddress,
        'status': status,
      };

  SlaveBoard copyWith({
    String? id,
    String? masterControllerId,
    String? deviceUid,
    String? name,
    int? modbusAddress,
    String? status,
  }) {
    return SlaveBoard(
      id: id ?? this.id,
      masterControllerId: masterControllerId ?? this.masterControllerId,
      deviceUid: deviceUid ?? this.deviceUid,
      name: name ?? this.name,
      modbusAddress: modbusAddress ?? this.modbusAddress,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
