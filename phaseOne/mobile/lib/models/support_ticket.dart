class SupportTicket {
  final String id;
  final String farmerId;
  final String? fieldId;
  final String? masterControllerId;
  final String? valveId;
  final String title;
  final String? description;
  final String priority; // low, medium, high, critical
  final String status; // open, inProgress, resolved, closed
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.farmerId,
    this.fieldId,
    this.masterControllerId,
    this.valveId,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      farmerId: json['farmerId']?.toString() ?? '',
      fieldId: json['fieldId']?.toString(),
      masterControllerId: json['masterControllerId']?.toString(),
      valveId: json['valveId']?.toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmerId': farmerId,
    'fieldId': fieldId,
    'masterControllerId': masterControllerId,
    'valveId': valveId,
    'title': title,
    'description': description,
    'priority': priority,
    'status': status,
  };
}
