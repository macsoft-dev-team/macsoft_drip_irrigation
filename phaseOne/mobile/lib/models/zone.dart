import 'valve.dart';

class Zone {
  final String id;
  final String fieldId;
  final String name;
  final String? description;
  final String status; // active, inactive
  final List<Valve> valves;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Zone({
    required this.id,
    required this.fieldId,
    required this.name,
    this.description,
    required this.status,
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
      fieldId: j['fieldId'] as String? ?? '',
      name: j['name'] as String? ?? '',
      description: j['description'] as String?,
      status: j['status'] as String? ?? 'active',
      valves: valvesList,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fieldId': fieldId,
        'name': name,
        'description': description,
        'status': status,
        'valves': valves.map((e) => e.toJson()).toList(),
      };

  Zone copyWith({
    String? id,
    String? fieldId,
    String? name,
    String? description,
    String? status,
    List<Valve>? valves,
  }) {
    return Zone(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      valves: valves ?? this.valves,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
