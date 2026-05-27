// Roles matching the backend JWT payload
enum UserRole { superadmin, admin, user }

UserRole _parseRole(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'SUPERADMIN':
      return UserRole.superadmin;
    case 'ADMIN':
      return UserRole.admin;
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

  const AppUser({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.role,
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
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: j['id'].toString(),
      name: j['name'] as String?,
      email: j['email'] as String?,
      phone: j['phone'] as String?,
      role: _parseRole(j['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.name.toUpperCase(),
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
