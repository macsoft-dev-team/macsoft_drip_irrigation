import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchCtrl = TextEditingController();
  String _lastSearch = '';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadUsers(page: 1, filter: '');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q == _lastSearch) return;
    _lastSearch = q;
    _page = 1;
    context.read<AppState>().loadUsers(page: 1, filter: q);
  }

  void _goPage(int p) {
    _page = p;
    context.read<AppState>().loadUsers(page: p, filter: _lastSearch);
  }

  void _showForm({AppUser? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _UserForm(
        user: user,
        onSaved: () {
          context.read<AppState>().loadUsers(page: _page, filter: _lastSearch);
        },
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete ${user.name ?? user.email}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Capture context-dependent values before async gap
    final state = context.read<AppState>();
    final token = state.token;
    if (token == null || !mounted) return;
    final page = _page;
    final filter = _lastSearch;
    try {
      await ApiService(token: token).deleteUser(user.id);
      if (!mounted) return;
      state.loadUsers(page: page, filter: filter);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, __) {
        final isSuperAdmin = state.user?.isSuperAdmin ?? false;
        final isAdmin = state.user?.isAdmin ?? false;
        if (!isAdmin) {
          return const Center(
            child: Text(
              'Access restricted',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          );
        }

        return Column(
          children: [
            // ── Toolbar ─────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: 'Search users…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _search('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _showForm(),
                  ),
                ],
              ),
            ),
            // ── List ────────────────────────────────────────────
            Expanded(
              child: state.usersLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.usersError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.usersError!,
                            style: const TextStyle(color: Color(0xFFEF4444)),
                          ),
                          TextButton(
                            onPressed: () => state.loadUsers(
                              page: _page,
                              filter: _lastSearch,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : state.users.isEmpty
                  ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: state.users.length,
                      itemBuilder: (_, i) => _UserTile(
                        user: state.users[i],
                        isSuperAdmin: isSuperAdmin,
                        onEdit: () => _showForm(user: state.users[i]),
                        onDelete: isSuperAdmin
                            ? () => _deleteUser(state.users[i])
                            : null,
                      ),
                    ),
            ),
            // ── Pagination ───────────────────────────────────────
            if (state.usersTotalPages > 1)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _page > 1 ? () => _goPage(_page - 1) : null,
                    ),
                    Text(
                      'Page $_page of ${state.usersTotalPages}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _page < state.usersTotalPages
                          ? () => _goPage(_page + 1)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final bool isSuperAdmin;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _UserTile({
    required this.user,
    required this.isSuperAdmin,
    required this.onEdit,
    this.onDelete,
  });

  static const _roleMeta = {
    UserRole.systemAdmin: ('SYSTEM_ADMIN', Color(0xFFFFF1F2), Color(0xFFE11D48)),
    UserRole.customerAdmin: ('CUSTOMER_ADMIN', Color(0xFFF5F3FF), Color(0xFF7C3AED)),
    UserRole.customerUser: ('CUSTOMER_USER', Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
    UserRole.customer: ('CUSTOMER', Color(0xFFF8FAFC), Color(0xFF6B7280)),
  };

  @override
  Widget build(BuildContext context) {
    final (label, bg, text) =
        _roleMeta[user.role] ??
        ('USER', const Color(0xFFF8FAFC), const Color(0xFF6B7280));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (user.name ?? user.email ?? '?').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                Text(
                  user.email ?? '—',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (user.phone != null && user.phone!.isNotEmpty)
                  Text(
                    user.phone!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: text.withValues(alpha: 0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: text,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            ),
            onPressed: onEdit,
            padding: const EdgeInsets.all(6),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.delete_rounded,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              onPressed: onDelete,
              padding: const EdgeInsets.all(6),
            ),
        ],
      ),
    );
  }
}

// ── User create/edit bottom sheet form ─────────────────────────────────────

class _UserForm extends StatefulWidget {
  final AppUser? user;
  final VoidCallback onSaved;
  const _UserForm({this.user, required this.onSaved});

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      final u = widget.user!;
      _nameCtrl.text = u.name ?? '';
      _emailCtrl.text = u.email ?? '';
      _phoneCtrl.text = u.phone ?? '';
      _role = u.role;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final token = appState.token;
    if (token == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = ApiService(token: token);
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': _role.name.toUpperCase(),
        if (_pwCtrl.text.isNotEmpty) 'password': _pwCtrl.text,
      };
      if (widget.user == null) {
        await api.createUser(data);
      } else {
        await api.updateUser(widget.user!.id, data);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final appState = context.watch<AppState>();
    final isSuperAdmin = appState.user?.isSuperAdmin ?? false;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    isEdit ? 'Edit User' : 'Add User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _fld(
                'Name',
                _nameCtrl,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              _fld(
                'Email',
                _emailCtrl,
                keyboard: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 12),
              _fld('Phone', _phoneCtrl, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _fld(
                isEdit ? 'Password (leave blank to keep)' : 'Password',
                _pwCtrl,
                obscure: true,
                validator: !isEdit
                    ? (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  const DropdownMenuItem(
                    value: UserRole.customer,
                    child: Text('CUSTOMER'),
                  ),
                  const DropdownMenuItem(
                    value: UserRole.customerUser,
                    child: Text('CUSTOMER_USER'),
                  ),
                  const DropdownMenuItem(
                    value: UserRole.customerAdmin,
                    child: Text('CUSTOMER_ADMIN'),
                  ),
                  if (isSuperAdmin)
                    const DropdownMenuItem(
                      value: UserRole.systemAdmin,
                      child: Text('SYSTEM_ADMIN'),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fld(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }
}
