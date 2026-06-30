// Roles matching the backend JWT payload
enum UserRole { systemAdmin, customerAdmin, customerUser, customer }

UserRole _parseRole(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'SYSTEM_ADMIN':
    case 'MACSOFT_ADMIN':
    case 'MACSOFT_USER':
    case 'SUPERADMIN':
    case 'ADMIN':
      return UserRole.systemAdmin;
    case 'CUSTOMER_ADMIN':
    case 'DISTRIBUTOR':
      return UserRole.customerAdmin;
    case 'CUSTOMER_USER':
    case 'END_USER':
    case 'TECHNICIAN':
      return UserRole.customerUser;
    case 'CUSTOMER':
    case 'FARMER':
    default:
      return UserRole.customer;
  }
}

class AppUser {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final UserRole role;
  final String? tenantId;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.role,
    this.tenantId,
  });

  // Getter for customerId to ensure backward compatibility
  String? get customerId => tenantId;

  factory AppUser.fromTokenPayload(Map<String, dynamic> payload) {
    return AppUser(
      id: (payload['id'] ?? payload['userId'] ?? '').toString(),
      name: payload['name'] as String?,
      email: payload['email'] as String?,
      phone: payload['phone'] as String?,
      role: _parseRole(
        payload['role'] as String? ?? payload['Role'] as String?,
      ),
      tenantId: (payload['tenantId'] ?? payload['customerId'])?.toString(),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final farmerId = j['farmer'] != null ? j['farmer']['id'] : null;
    final distributorId = j['distributor'] != null ? j['distributor']['id'] : null;
    final dealerId = j['dealer'] != null ? j['dealer']['id'] : null;

    return AppUser(
      id: j['id'].toString(),
      name: j['name'] as String?,
      email: j['email'] as String?,
      phone: j['phone'] as String?,
      role: _parseRole(j['role'] as String?),
      tenantId: (j['tenantId'] ?? j['customerId'] ?? farmerId ?? distributorId ?? dealerId)?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name.toUpperCase(),
    'tenantId': tenantId,
  };

  // ── RBAC helpers ──────────────────────────────────────────
  bool get isSuperAdmin => role == UserRole.systemAdmin;
  bool get isAdmin => role == UserRole.systemAdmin || role == UserRole.customerAdmin;
  bool get canManageUsers => isAdmin;
  bool get canDeleteUsers => isSuperAdmin;
  bool get canManageDevices => isAdmin;
  bool get canManageFields => role == UserRole.systemAdmin || role == UserRole.customerAdmin || role == UserRole.customerUser;

  // Feature Access
  bool get canAccessSchedules => role != UserRole.customer; // Operator cannot access schedules
  bool get canAccessStore => role == UserRole.systemAdmin; // Only System Admin can access store
  bool get canAccessUsersPage => role == UserRole.systemAdmin || role == UserRole.customerAdmin; // Admin or Farmer
  bool get canAccessSupport => role != UserRole.customer; // Operator doesn't get support desk access

  // Hardware/Commissioning Actions
  bool get canCommissionDevices => role == UserRole.systemAdmin || role == UserRole.customerUser; // Admin or Technician
  bool get canConfigureModbus => role == UserRole.systemAdmin || role == UserRole.customerUser;
  bool get canAddValves => role == UserRole.systemAdmin || role == UserRole.customerUser;

  // Irrigation & Configuration Management
  bool get canCreateZones => role == UserRole.systemAdmin || role == UserRole.customerAdmin || role == UserRole.customerUser;
  bool get canCreateSchedules => role == UserRole.systemAdmin || role == UserRole.customerAdmin; // Admin or Farmer
  bool get canOperateIrrigation => true; // All roles can toggle manual irrigation
  bool get canViewDeviceLogs => role != UserRole.customer; // Operator cannot view logs
  bool get canPerformOTA => role == UserRole.systemAdmin || role == UserRole.customerUser; // Admin or Technician

  String get roleLabel {
    switch (role) {
      case UserRole.systemAdmin:
        return 'System Admin';
      case UserRole.customerAdmin:
        return 'Customer Admin';
      case UserRole.customerUser:
        return 'Customer User';
      case UserRole.customer:
        return 'Customer';
    }
  }
}
