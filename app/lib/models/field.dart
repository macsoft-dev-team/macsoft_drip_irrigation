import 'zone.dart';
import 'master_controller.dart';

class Field {
  final String id;
  final String farmerId;
  final String name;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final double? areaAcres;
  final String status; // active, inactive
  final MasterController? masterController;
  final List<Zone> zones;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Field({
    required this.id,
    required this.farmerId,
    required this.name,
    this.locationName,
    this.latitude,
    this.longitude,
    this.areaAcres,
    required this.status,
    this.masterController,
    this.zones = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Field.fromJson(Map<String, dynamic> j) {
    final zonesList = (j['zones'] as List<dynamic>?)
            ?.map((e) => Zone.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final mc = j['masterController'] != null
        ? MasterController.fromJson(j['masterController'] as Map<String, dynamic>)
        : null;

    return Field(
      id: j['id'].toString(),
      farmerId: j['farmerId']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      locationName: j['locationName'] as String?,
      latitude: j['latitude'] != null ? double.tryParse(j['latitude'].toString()) : null,
      longitude: j['longitude'] != null ? double.tryParse(j['longitude'].toString()) : null,
      areaAcres: j['areaAcres'] != null ? double.tryParse(j['areaAcres'].toString()) : null,
      status: j['status'] as String? ?? 'active',
      masterController: mc,
      zones: zonesList,
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmerId': farmerId,
        'name': name,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'areaAcres': areaAcres,
        'status': status,
        'masterController': masterController?.toJson(),
        'zones': zones.map((e) => e.toJson()).toList(),
      };

  Field copyWith({
    String? id,
    String? farmerId,
    String? name,
    String? locationName,
    double? latitude,
    double? longitude,
    double? areaAcres,
    String? status,
    MasterController? masterController,
    List<Zone>? zones,
  }) {
    return Field(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      areaAcres: areaAcres ?? this.areaAcres,
      status: status ?? this.status,
      masterController: masterController ?? this.masterController,
      zones: zones ?? this.zones,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
