import 'zone.dart';

class Field {
  final String id;
  final String name;
  final String customerId;
  final List<Zone> zones;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Field({
    required this.id,
    required this.name,
    required this.customerId,
    this.zones = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Field.fromJson(Map<String, dynamic> j) {
    final zonesList = (j['zones'] as List<dynamic>?)
            ?.map((e) => Zone.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return Field(
      id: j['id'].toString(),
      name: j['name'] as String? ?? '',
      customerId: j['customerId'] as String? ?? '',
      zones: zonesList,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'customerId': customerId,
        'zones': zones.map((e) => e.toJson()).toList(),
      };

  Field copyWith({
    String? id,
    String? name,
    String? customerId,
    List<Zone>? zones,
  }) {
    return Field(
      id: id ?? this.id,
      name: name ?? this.name,
      customerId: customerId ?? this.customerId,
      zones: zones ?? this.zones,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
