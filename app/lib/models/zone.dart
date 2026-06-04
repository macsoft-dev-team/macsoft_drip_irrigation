import 'valve.dart';

class Zone {
  final String id;
  final String name;
  final String fieldId;
  final List<Valve> valves;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Zone({
    required this.id,
    required this.name,
    required this.fieldId,
    this.valves = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Zone.fromJson(Map<String, dynamic> j) {
    final valvesList = (j['valves'] as List<dynamic>?)
            ?.map((e) => Valve.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return Zone(
      id: j['id'].toString(),
      name: j['name'] as String? ?? '',
      fieldId: j['fieldId'] as String? ?? '',
      valves: valvesList,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fieldId': fieldId,
        'valves': valves.map((e) => e.toJson()).toList(),
      };

  Zone copyWith({
    String? id,
    String? name,
    String? fieldId,
    List<Valve>? valves,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      fieldId: fieldId ?? this.fieldId,
      valves: valves ?? this.valves,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
