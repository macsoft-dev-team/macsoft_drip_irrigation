// Roles matching the backend JWT payload
enum UserRole { superadmin, admin, user }

UserRole _parseRole(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'MACSOFT_ADMIN':
    case 'MACSOFT_USER':
    case 'SUPERADMIN':
      return UserRole.superadmin;
    case 'CUSTOMER_ADMIN':
    case 'ADMIN':
      return UserRole.admin;
    case 'CUSTOMER_USER':
    case 'END_USER':
    default:
      return UserRole.user;
  }
}

class AppUser {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final UserRole role;
  final String? customerId;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.role,
    this.customerId,
  });

  factory AppUser.fromTokenPayload(Map<String, dynamic> payload) {
    return AppUser(
      id: payload['id'].toString(),
      name: payload['name'] as String?,
      email: payload['email'] as String?,
      phone: payload['phone'] as String?,
      role: _parseRole(
        payload['role'] as String? ?? payload['Role'] as String?,
      ),
      customerId: payload['customerId']?.toString(),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: j['id'].toString(),
      name: j['name'] as String?,
      email: j['email'] as String?,
      phone: j['phone'] as String?,
      role: _parseRole(j['role'] as String?),
      customerId: j['customerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name.toUpperCase(),
    'customerId': customerId,
  };

  // ── RBAC helpers ──────────────────────────────────────────
  bool get isSuperAdmin => role == UserRole.superadmin;
  bool get isAdmin => role == UserRole.superadmin || role == UserRole.admin;
  bool get canManageUsers => isAdmin;
  bool get canDeleteUsers => isSuperAdmin;
  bool get canManageDevices => isAdmin;

  String get roleLabel {
    switch (role) {
      case UserRole.superadmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.user:
        return 'User';
    }
  }
}
