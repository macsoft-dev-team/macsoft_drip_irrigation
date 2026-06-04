class Valve {
  final String id;
  final String name;
  final String zoneId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Valve({
    required this.id,
    required this.name,
    required this.zoneId,
    this.createdAt,
    this.updatedAt,
  });

  factory Valve.fromJson(Map<String, dynamic> j) {
    return Valve(
      id: j['id'].toString(),
      name: j['name'] as String? ?? '',
      zoneId: j['zoneId'] as String? ?? '',
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'zoneId': zoneId,
      };

  Valve copyWith({
    String? id,
    String? name,
    String? zoneId,
  }) {
    return Valve(
      id: id ?? this.id,
      name: name ?? this.name,
      zoneId: zoneId ?? this.zoneId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
