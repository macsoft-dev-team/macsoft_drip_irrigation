class Farmer {
  final String id;
  final String userId;
  final String? distributorId;
  final String? address;
  final String? village;
  final String? district;
  final String? state;
  final String? pincode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Farmer({
    required this.id,
    required this.userId,
    this.distributorId,
    this.address,
    this.village,
    this.district,
    this.state,
    this.pincode,
    this.createdAt,
    this.updatedAt,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      distributorId: json['distributorId']?.toString(),
      address: json['address'] as String?,
      village: json['village'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'distributorId': distributorId,
    'address': address,
    'village': village,
    'district': district,
    'state': state,
    'pincode': pincode,
  };
}
