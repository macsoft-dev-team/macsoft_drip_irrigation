import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/api_device.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../services/socket_service.dart';
import '../widgets/import_devices_sheet.dart';
import 'device_list_page.dart';
import 'user_device_page.dart';
import 'users_page.dart';

class DashboardPage extends StatefulWidget {
  final bool useLegacyShell;

  const DashboardPage({super.key, this.useLegacyShell = false});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  static const _primary = Color(0xFF1565C0);

  // User device list — search & filter
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'all'; // all | online | offline | fault

  @override
  void initState() {
    super.initState();
    if (widget.useLegacyShell) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
    }
  }

  Future<void> _boot() async {
    final state = context.read<AppState>();
    await state.loadDevices();
    if (state.token != null) {
      SocketService.instance.connect(state.token!);
      SocketService.instance.addListener(_onTelemetry);
    }
  }

  void _onTelemetry(String deviceId, TelemetryRow row) {
    context.read<AppState>().updateDeviceLive(deviceId, row);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    SocketService.instance.removeListener(_onTelemetry);
    super.dispose();
  }

  Future<void> _logout() async {
    SocketService.instance.disconnect();
    await context.read<AppState>().logout();
  }

  // ── Farmer dashboard (primary view used by AppShell) ─────────────────────

  static const _primaryGreen = Color(0xFF37B34A);
  static const _darkText = Color(0xFF1E2A1F);
  static const _greyText = Color(0xFF8A958A);

  Widget _buildFarmerDashboard(AppState state) {
    final user = state.user;
    final devices = state.devices;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
        ? 'Good Afternoon,'
        : 'Good Evening,';
    final isAdmin = user?.isAdmin ?? false;

    return RefreshIndicator(
      onRefresh: state.loadDevices,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ───────────────────────────────────
            _topBar(user),
            const SizedBox(height: 16),

            Text(
              greeting,
              style: const TextStyle(
                fontSize: 14,
                color: _greyText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    user?.name ?? 'Dashboard',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _darkText,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                _RoleBadge(role: user?.role ?? UserRole.user),
              ],
            ),
            const SizedBox(height: 18),

            // ── Weather / Farm scene card ──────────────────
            _weatherCard(),
            const SizedBox(height: 20),

            // ── Today's Overview ──────────────────────────
            _sectionHeader("Today's Overview"),
            const SizedBox(height: 12),
            _buildOverviewCards(state, isAdmin),
            const SizedBox(height: 22),

            // ── Quick Actions ─────────────────────────────
            _sectionHeader('Quick Actions'),
            const SizedBox(height: 12),
            _buildQuickActions(state, isAdmin),
            const SizedBox(height: 22),

            // ── Recent / My Devices ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader(isAdmin ? 'Recent Devices' : 'My Devices'),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: _primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (state.devicesLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _primaryGreen),
                ),
              )
            else if (state.devicesError != null)
              _ErrorTile(
                message: state.devicesError!,
                onRetry: state.loadDevices,
              )
            else if (devices.isEmpty)
              _EmptyDevices(isAdmin: isAdmin)
            else
              ...devices.take(5).map((d) => _DeviceFarmTile(device: d)),
          ],
        ),
      ),
    );
  }

  Widget _topBar(AppUser? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.water_drop_rounded, color: _primaryGreen, size: 26),
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: _darkText,
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 13),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE2F3D5),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user?.name?.isNotEmpty == true
                      ? user!.name![0].toUpperCase()
                      : '🌿',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _weatherCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                const Text('🌤️', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '28°C',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _darkText,
                        ),
                      ),
                      Text(
                        'Partly Cloudy',
                        style: TextStyle(
                          color: _greyText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _weatherInfo('Humidity', '60%'),
                const SizedBox(width: 14),
                _weatherInfo('Wind', '12 km/h'),
              ],
            ),
          ),
          SizedBox(
            height: 105,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
              child: const AnimatedFarmScene(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _weatherInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _greyText,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _darkText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(AppState state, bool isAdmin) {
    final devices = state.devices;
    final online = devices.where((d) => d.isActive).length;
    final offline = devices.length - online;
    final faults = devices.where((d) {
      final sts = (d.telemetryLogs.firstOrNull?.sts as num?)?.toInt() ?? 0;
      return d.isActive && sts != 0;
    }).length;

    final List<_OverviewCardData> cards = isAdmin
        ? [
            _OverviewCardData(
              icon: Icons.devices_rounded,
              title: 'Total Devices',
              value: '${devices.length}',
              subtitle: 'Registered',
              iconBg: const Color(0xFFE8F5E9),
              iconColor: _primaryGreen,
            ),
            _OverviewCardData(
              icon: Icons.wifi_rounded,
              title: 'Active Now',
              value: '$online',
              subtitle: 'Online',
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1976D2),
            ),
            _OverviewCardData(
              icon: Icons.people_rounded,
              title: 'Users',
              value: state.users.isNotEmpty ? '${state.users.length}' : '–',
              subtitle: 'Managed',
              iconBg: const Color(0xFFF3E5F5),
              iconColor: const Color(0xFF7B1FA2),
            ),
            _OverviewCardData(
              icon: Icons.warning_amber_rounded,
              title: 'Faults',
              value: '$faults',
              subtitle: 'Need attention',
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFF57C00),
            ),
          ]
        : [
            _OverviewCardData(
              icon: Icons.devices_other_rounded,
              title: 'My Devices',
              value: '${devices.length}',
              subtitle: 'Assigned',
              iconBg: const Color(0xFFE8F5E9),
              iconColor: _primaryGreen,
            ),
            _OverviewCardData(
              icon: Icons.power_settings_new_rounded,
              title: 'Running',
              value: '$online',
              subtitle: 'Active motors',
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1976D2),
            ),
            _OverviewCardData(
              icon: Icons.wifi_off_rounded,
              title: 'Offline',
              value: '$offline',
              subtitle: 'Not connected',
              iconBg: const Color(0xFFFCE4EC),
              iconColor: const Color(0xFFD32F2F),
            ),
            _OverviewCardData(
              icon: Icons.report_problem_outlined,
              title: 'Faults',
              value: '$faults',
              subtitle: 'Review needed',
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFF57C00),
            ),
          ];

    return Row(
      children: List.generate(cards.length, (i) {
        final c = cards[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < cards.length - 1 ? 8 : 0),
            child: _OverviewCard(
              icon: c.icon,
              title: c.title,
              value: c.value,
              subtitle: c.subtitle,
              iconBg: c.iconBg,
              iconColor: c.iconColor,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuickActions(AppState state, bool isAdmin) {
    final List<_ActionData> actions = isAdmin
        ? [
            _ActionData(
              icon: Icons.upload_file_rounded,
              label: 'Import\nDevices',
              onTap: () => ImportDevicesSheet.show(
                context,
                token: state.token ?? '',
                onSuccess: state.loadDevices,
              ),
            ),
            _ActionData(
              icon: Icons.people_outline_rounded,
              label: 'Manage\nUsers',
              onTap: () {},
            ),
            _ActionData(
              icon: Icons.send_rounded,
              label: 'Send\nCommand',
              onTap: () {},
            ),
            _ActionData(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              onTap: () {},
            ),
          ]
        : [
            _ActionData(
              icon: Icons.devices_outlined,
              label: 'My\nDevices',
              onTap: () {},
            ),
            _ActionData(
              icon: Icons.notifications_active_outlined,
              label: 'View\nAlerts',
              onTap: () {},
            ),
            _ActionData(
              icon: Icons.monitor_heart_outlined,
              label: 'Telemetry',
              onTap: () {},
            ),
            _ActionData(
              icon: Icons.schedule_rounded,
              label: 'Schedule',
              onTap: () {},
            ),
          ];

    return Row(
      children: List.generate(actions.length, (i) {
        final a = actions[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < actions.length - 1 ? 8 : 0),
            child: _ActionCard(icon: a.icon, label: a.label, onTap: a.onTap),
          ),
        );
      }),
    );
  }

  static Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _darkText,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  List<ApiDevice> _applyUserFilters(List<ApiDevice> devices) {
    final q = _search.trim().toLowerCase();
    return devices.where((d) {
      // search
      if (q.isNotEmpty &&
          !(d.name ?? '').toLowerCase().contains(q) &&
          !d.imeinumber.toLowerCase().contains(q))
        return false;
      // status
      if (_statusFilter == 'online' && !d.isActive) return false;
      if (_statusFilter == 'offline' && d.isActive) return false;
      if (_statusFilter == 'fault') {
        final sts = (d.telemetryLogs.firstOrNull?.sts as num?)?.toInt() ?? 0;
        final hasFault = sts != 0;
        if (!d.isActive || !hasFault) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildUserScaffold(AppState state) {
    final devices = state.devices;
    final filtered = _applyUserFilters(devices);
    final total = devices.length;
    final online = devices.where((d) => d.isActive).length;
    final offline = total - online;
    final faultCount = devices.where((d) {
      final sts = (d.telemetryLogs.firstOrNull?.sts as num?)?.toInt() ?? 0;
      return d.isActive && sts != 0;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('My Devices'),
          ],
        ),
        actions: [
          if (state.user != null) Center(child: _UserChip(user: state.user!)),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter bar ──────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Summary pills
                Row(
                  children: [
                    _SummaryPill(
                      label: '$online Online',
                      dot: const Color(0xFF3B82F6),
                      pulse: true,
                    ),
                    const SizedBox(width: 8),
                    _SummaryPill(
                      label: '$offline Offline',
                      dot: const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    _SummaryPill(label: '$total Total'),
                  ],
                ),
                const SizedBox(height: 10),
                // Search field
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name or IMEI…',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() {
                              _search = '';
                              _searchCtrl.clear();
                            }),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF93C5FD),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Status dropdown
                DropdownButtonFormField<String>(
                  value: _statusFilter,
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF93C5FD),
                        width: 1.5,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  items: [
                    _filterItem('all', 'All Devices ($total)'),
                    _filterItem('online', 'Online ($online)'),
                    _filterItem('offline', 'Offline ($offline)'),
                    _filterItem('fault', 'Fault ($faultCount)'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── List ─────────────────────────────────────────
          Expanded(
            child: state.devicesLoading
                ? const Center(child: CircularProgressIndicator())
                : state.devicesError != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: _ErrorTile(
                      message: state.devicesError!,
                      onRetry: state.loadDevices,
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_other_rounded,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          devices.isEmpty
                              ? 'No devices assigned'
                              : 'No devices match',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          devices.isEmpty
                              ? 'Contact your administrator to add devices.'
                              : 'Try adjusting your search or filter.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        if (_search.isNotEmpty || _statusFilter != 'all') ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() {
                              _search = '';
                              _searchCtrl.clear();
                              _statusFilter = 'all';
                            }),
                            child: const Text(
                              'Clear filters',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: state.loadDevices,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, idx) {
                        final d = filtered[idx];
                        return _UserDeviceTile(
                          device: d,
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => UserDevicePage(device: d),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _filterItem(String value, String label) {
    return DropdownMenuItem(value: value, child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.useLegacyShell) {
      return Consumer<AppState>(
        builder: (context, state, _) => _buildFarmerDashboard(state),
      );
    }

    return Consumer<AppState>(
      builder: (_, state, __) {
        if (state.user?.role == UserRole.user) {
          return _buildUserScaffold(state);
        }
        final isAdmin =
            state.user?.role == UserRole.admin ||
            state.user?.role == UserRole.superadmin;
        final titles = ['Overview', 'Devices', if (isAdmin) 'Users'];
        final pages = [
          _buildFarmerDashboard(state),
          const DeviceListPage(),
          if (isAdmin) const UsersPage(),
        ];
        final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', height: 28),
                const SizedBox(width: 8),
                Text(titles[safeIndex]),
              ],
            ),
            actions: [
              if (state.user != null)
                Center(child: _UserChip(user: state.user!)),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign out',
                onPressed: _logout,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: pages[safeIndex],
          floatingActionButton: safeIndex == 1 && isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => ImportDevicesSheet.show(
                    context,
                    token: state.token ?? '',
                    onSuccess: state.loadDevices,
                  ),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Import'),
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Overview',
              ),
              const NavigationDestination(
                icon: Icon(Icons.devices_outlined),
                selectedIcon: Icon(Icons.devices),
                label: 'Devices',
              ),
              if (isAdmin)
                const NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'Users',
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _UserChip extends StatelessWidget {
  final AppUser user;
  const _UserChip({required this.user});

  @override
  Widget build(BuildContext context) {
    final (roleLabel, roleColor, roleBg) = switch (user.role) {
      UserRole.superadmin => (
        'Super Admin',
        const Color(0xFFBE123C),
        const Color(0xFFFFF1F2),
      ),
      UserRole.admin => (
        'Admin',
        const Color(0xFF6D28D9),
        const Color(0xFFF5F3FF),
      ),
      UserRole.user => (
        'User',
        const Color(0xFF0369A1),
        const Color(0xFFEFF6FF),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: roleBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: user.name?.isNotEmpty == true
                  ? Text(
                      user.name![0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: roleColor,
                      ),
                    )
                  : Icon(Icons.person, size: 13, color: roleColor),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            user.name ?? 'User',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: roleColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSummaryTile extends StatefulWidget {
  final ApiDevice device;
  const _DeviceSummaryTile({required this.device});

  @override
  State<_DeviceSummaryTile> createState() => _DeviceSummaryTileState();
}

class _DeviceSummaryTileState extends State<_DeviceSummaryTile> {
  bool _sending = false;

  static String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  /// Motor is considered running when any phase current > 0.1 A
  bool get _isRunning {
    final t = widget.device.telemetryLogs.firstOrNull;
    if (t == null) return false;
    return (t.ic1 ?? 0) > 0.1 || (t.ic2 ?? 0) > 0.1 || (t.ic3 ?? 0) > 0.1;
  }

  Future<void> _sendPower(bool on) async {
    final token = context.read<AppState>().token;
    if (token == null) return;
    setState(() => _sending = true);
    try {
      await ApiService(
        token: token,
      ).sendCommand(widget.device.id, {'PWR': on ? 1 : 0});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            on
                ? 'START sent to ${widget.device.name ?? widget.device.imeinumber}'
                : 'STOP sent',
          ),
          backgroundColor: on
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.device.telemetryLogs.firstOrNull;
    final isRunning = _isRunning;
    final lastHb = widget.device.lastHeartbeat;
    final rmd = widget.device.config?['rmd'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: icon + name + badges ──────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.device.isActive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.router_rounded,
                  size: 18,
                  color: widget.device.isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.device.name ?? widget.device.imeinumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    Text(
                      widget.device.imeinumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              // Status badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _DotBadge(
                    label: widget.device.isActive ? 'Online' : 'Offline',
                    color: widget.device.isActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 4),
                  if (widget.device.isActive)
                    _DotBadge(
                      label: isRunning ? 'Running' : 'Idle',
                      color: isRunning
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD97706),
                    )
                  else if (rmd != null)
                    Builder(
                      builder: (_) {
                        final isAuto = (rmd as num).toInt() == 1;
                        return _DotBadge(
                          label: isAuto ? 'Auto' : 'Manual',
                          color: isAuto
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF9CA3AF),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),

          // ── Telemetry summary row ───────────────────────────
          if (latest != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF8FAFC)),
            const SizedBox(height: 8),
            Row(
              children: [
                _MiniStat(
                  label: 'V1',
                  value: latest.iv1 != null
                      ? '${latest.iv1!.toStringAsFixed(0)}V'
                      : '—',
                ),
                _MiniStat(
                  label: 'V2',
                  value: latest.iv2 != null
                      ? '${latest.iv2!.toStringAsFixed(0)}V'
                      : '—',
                ),
                _MiniStat(
                  label: 'V3',
                  value: latest.iv3 != null
                      ? '${latest.iv3!.toStringAsFixed(0)}V'
                      : '—',
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  label: 'A1',
                  value: latest.ic1 != null
                      ? '${latest.ic1!.toStringAsFixed(1)}A'
                      : '—',
                  color: const Color(0xFFD97706),
                ),
                _MiniStat(
                  label: 'A2',
                  value: latest.ic2 != null
                      ? '${latest.ic2!.toStringAsFixed(1)}A'
                      : '—',
                  color: const Color(0xFFD97706),
                ),
                _MiniStat(
                  label: 'A3',
                  value: latest.ic3 != null
                      ? '${latest.ic3!.toStringAsFixed(1)}A'
                      : '—',
                  color: const Color(0xFFD97706),
                ),
                const Spacer(),
                if (lastHb != null)
                  Text(
                    _ago(lastHb),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Tank level indicators ───────────────────────
            _TankLevelRow(flc: latest.flc),
          ] else if (lastHb != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _ago(lastHb),
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],

          // ── START / STOP button ─────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _sending
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : widget.device.isActive
                    ? Row(
                        children: [
                          Expanded(
                            child: _CmdButton(
                              label: 'START',
                              icon: Icons.play_arrow_rounded,
                              color: const Color(0xFF059669),
                              onTap: isRunning ? null : () => _sendPower(true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CmdButton(
                              label: 'STOP',
                              icon: Icons.stop_rounded,
                              color: const Color(0xFFDC2626),
                              onTap: isRunning ? () => _sendPower(false) : null,
                            ),
                          ),
                        ],
                      )
                    : _CmdButton(
                        label: 'Device Offline',
                        icon: Icons.wifi_off_rounded,
                        color: const Color(0xFF9CA3AF),
                        onTap: null,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tank level indicator row ──────────────────────────────────────────────────
//
// flc is a bitmask from the motor controller float sensors:
//   bit 0 (flc & 1): Low-level float switch  — 1 = LOW level triggered
//   bit 1 (flc & 2): High-level float switch — 1 = HIGH level triggered

class _TankLevelRow extends StatelessWidget {
  final dynamic flc;
  const _TankLevelRow({required this.flc});

  @override
  Widget build(BuildContext context) {
    final v = flc != null ? (flc as num).toInt() : 0;
    final isLow = (v & 1) == 1; // bit 0
    final isHigh = (v & 2) == 2; // bit 1

    return Row(
      children: [
        const Icon(
          Icons.water_drop_rounded,
          size: 12,
          color: Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 5),
        const Text(
          'Tank',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(width: 8),
        _TankBadge(
          label: 'HIGH',
          active: isHigh,
          activeColor: const Color(0xFF0369A1),
          activeBg: const Color(0xFFEFF6FF),
          activeBorder: const Color(0xFFBAE6FD),
          inactiveLabel: 'HIGH',
        ),
        const SizedBox(width: 6),
        _TankBadge(
          label: 'LOW',
          active: isLow,
          activeColor: const Color(0xFFDC2626),
          activeBg: const Color(0xFFFEF2F2),
          activeBorder: const Color(0xFFFECACA),
          inactiveLabel: 'LOW',
        ),
        if (!isHigh && !isLow) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Text(
              'NORMAL',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TankBadge extends StatelessWidget {
  final String label;
  final String inactiveLabel;
  final bool active;
  final Color activeColor;
  final Color activeBg;
  final Color activeBorder;
  const _TankBadge({
    required this.label,
    required this.inactiveLabel,
    required this.active,
    required this.activeColor,
    required this.activeBg,
    required this.activeBorder,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          inactiveLabel,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFFCBD5E1),
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: activeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: activeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: activeColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small dot + text status badge ────────────────────────────────────────────

class _DotBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _DotBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Inline voltage/current mini stat ─────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    this.color = const Color(0xFF1565C0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── START / STOP command button ───────────────────────────────────────────────

class _CmdButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _CmdButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.09)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: enabled ? color : const Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: enabled ? color : const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User device list tile ─────────────────────────────────────────────────────

// ── User device list tile (mirrors MyDevicesPage.jsx DeviceCard) ──────────────

class _UserDeviceTile extends StatelessWidget {
  final ApiDevice device;
  final VoidCallback onTap;
  const _UserDeviceTile({required this.device, required this.onTap});

  // STS bitmask — mirrors JS STS_FAULTS
  static const _stsBits = [
    (bit: 0, label: 'Phase Fault', isRed: true),
    (bit: 1, label: 'Overcurrent', isRed: true),
    (bit: 2, label: 'Overvoltage', isRed: false),
    (bit: 3, label: 'Undervoltage', isRed: false),
  ];

  static List<({int bit, String label, bool isRed})> _faults(dynamic sts) {
    final v = (sts as num?)?.toInt() ?? 0;
    if (v == 0) return [];
    return _stsBits.where((f) => (v >> f.bit) & 1 == 1).toList();
  }

  // blue = running, yellow = warning, red = fault/offline
  static _CardTheme _theme(ApiDevice d, TelemetryRow? latest) {
    if (!d.isActive) return _CardTheme.red;
    final f = _faults(latest?.sts);
    if (f.any((x) => x.isRed)) return _CardTheme.red;
    if (f.isNotEmpty) return _CardTheme.yellow;
    return _CardTheme.blue;
  }

  static String _fmtTime(DateTime? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final latest = device.telemetryLogs.firstOrNull;
    final theme = _theme(device, latest);
    final faults = _faults(latest?.sts);
    final firstFault = faults.firstOrNull;

    final label = switch (theme) {
      _CardTheme.blue => 'Running',
      _CardTheme.yellow => 'Warning',
      _CardTheme.red => device.isActive ? 'Fault' : 'Offline',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icon box ─────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.developer_board_rounded,
                size: 22,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.badgeBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pulse dot for running
                            _PulseDot(
                              color: theme.dot,
                              pulse: theme == _CardTheme.blue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: theme.badgeFg,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (firstFault != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '⚠ ${firstFault.label}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Device name (monospace bold)
                  Text(
                    device.name ?? device.imeinumber,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (device.name != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      device.imeinumber,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),

                  // Mini stats: IV1 | FLC | time
                  latest != null
                      ? Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 12,
                              color: theme.badgeFg.withOpacity(0.7),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              latest.iv1 != null
                                  ? '${latest.iv1!.toStringAsFixed(0)} V'
                                  : '—',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.water_drop_outlined,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              latest.flc != null ? '${latest.flc} LPM' : '—',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _fmtTime(latest.time),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'No telemetry yet',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                ],
              ),
            ),

            // ── Chevron ──────────────────────────────────────
            Icon(Icons.chevron_right_rounded, size: 22, color: theme.chevron),
          ],
        ),
      ),
    );
  }
}

// Card color theme enum (mirrors STATUS_STYLES in MyDevicesPage.jsx)
enum _CardTheme {
  blue(
    bg: Color(0xFFF0F9FF),
    border: Color(0xFFBFDBFE),
    badgeBg: Color(0xFFEFF6FF),
    badgeFg: Color(0xFF1D4ED8),
    dot: Color(0xFF3B82F6),
    chevron: Color(0xFF93C5FD),
  ),
  yellow(
    bg: Color(0xFFFFFBEB),
    border: Color(0xFFFDE68A),
    badgeBg: Color(0xFFFEF9C3),
    badgeFg: Color(0xFFB45309),
    dot: Color(0xFFF59E0B),
    chevron: Color(0xFFFCD34D),
  ),
  red(
    bg: Color(0xFFFFF5F5),
    border: Color(0xFFFECACA),
    badgeBg: Color(0xFFFEF2F2),
    badgeFg: Color(0xFFB91C1C),
    dot: Color(0xFFEF4444),
    chevron: Color(0xFFFCA5A5),
  );

  const _CardTheme({
    required this.bg,
    required this.border,
    required this.badgeBg,
    required this.badgeFg,
    required this.dot,
    required this.chevron,
  });

  final Color bg;
  final Color border;
  final Color badgeBg;
  final Color badgeFg;
  final Color dot;
  final Color chevron;
}

// Animated pulse dot (mirrors Tailwind animate-pulse)
class _PulseDot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _PulseDot({required this.color, required this.pulse});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.pulse ? _anim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}

// ── Summary pill (user device header) ────────────────────────────────────────

class _SummaryPill extends StatelessWidget {
  final String label;
  final Color? dot;
  final bool pulse;
  const _SummaryPill({required this.label, this.dot, this.pulse = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dot != null ? dot!.withOpacity(0.08) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dot != null ? dot!.withOpacity(0.25) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dot != null
                  ? dot!.withOpacity(0.85)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error tile ────────────────────────────────────────────────────────────────

class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: Color(0xFFBE123C)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (role) {
      UserRole.superadmin => (
        'Super Admin',
        const Color(0xFFBE123C),
        const Color(0xFFFFF1F2),
      ),
      UserRole.admin => (
        'Admin',
        const Color(0xFF6D28D9),
        const Color(0xFFF5F3FF),
      ),
      UserRole.user => (
        'Farmer',
        const Color(0xFF15803D),
        const Color(0xFFF0FDF4),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Empty devices placeholder ─────────────────────────────────────────────────

class _EmptyDevices extends StatelessWidget {
  final bool isAdmin;
  const _EmptyDevices({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.devices_other_rounded,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              isAdmin ? 'No devices yet' : 'No devices assigned',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAdmin
                  ? 'Import devices to get started.'
                  : 'Contact your administrator to add devices.',
              style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Farm-style device tile ────────────────────────────────────────────────────

class _DeviceFarmTile extends StatelessWidget {
  final ApiDevice device;
  const _DeviceFarmTile({required this.device});

  @override
  Widget build(BuildContext context) {
    final latest = device.telemetryLogs.firstOrNull;
    final isRunning =
        latest != null &&
        ((latest.ic1 ?? 0) > 0.1 ||
            (latest.ic2 ?? 0) > 0.1 ||
            (latest.ic3 ?? 0) > 0.1);
    final faultSts = (latest?.sts as num?)?.toInt() ?? 0;
    final hasFault = faultSts != 0;

    final (statusLabel, statusColor, statusBg) = !device.isActive
        ? ('Offline', const Color(0xFF9CA3AF), const Color(0xFFF8FAFC))
        : hasFault
        ? ('Fault', const Color(0xFFEF4444), const Color(0xFFFFF5F5))
        : isRunning
        ? ('Running', const Color(0xFF37B34A), const Color(0xFFF0FDF4))
        : ('Idle', const Color(0xFFF59E0B), const Color(0xFFFFFBEB));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.developer_board_rounded,
              size: 22,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),

          // Name + IMEI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name ?? device.imeinumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2A1F),
                  ),
                ),
                if (device.name != null)
                  Text(
                    device.imeinumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                if (latest != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      Text(
                        latest.iv1 != null
                            ? '${latest.iv1!.toStringAsFixed(0)} V'
                            : '—',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.water_drop_outlined,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      Text(
                        latest.flc != null ? '${latest.flc}' : '—',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data holders ──────────────────────────────────────────────────────────────

class _OverviewCardData {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;
  const _OverviewCardData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
  });
}

class _ActionData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// ── Overview card ─────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconBg;
  final Color iconColor;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8A958A),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1E2A1F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9FA89F),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF37B34A), size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1E2A1F),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated farm scene ───────────────────────────────────────────────────────

class AnimatedFarmScene extends StatefulWidget {
  const AnimatedFarmScene({super.key});

  @override
  State<AnimatedFarmScene> createState() => _AnimatedFarmSceneState();
}

class _AnimatedFarmSceneState extends State<AnimatedFarmScene>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: FarmPainter(animationValue: _controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

// ── Farm painter ──────────────────────────────────────────────────────────────

class FarmPainter extends CustomPainter {
  final double animationValue;

  FarmPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // ── Sky gradient ─────────────────────────────────────
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD4EDFF), Color(0xFFEFFBE9)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // ── Sun ───────────────────────────────────────────────
    _drawSun(
      canvas,
      Offset(size.width * 0.85, size.height * 0.12),
      animationValue,
    );

    // ── Drifting clouds ───────────────────────────────────
    _drawCloud(canvas, size, animationValue, 0.0, 0.14, 0.28);
    _drawCloud(canvas, size, animationValue, 0.4, 0.06, 0.18);

    // ── Background hills ──────────────────────────────────
    final hillPaint = Paint()..color = const Color(0xFFB9E0A2);
    final hillPath = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.15,
        size.width * 0.52,
        size.height * 0.48,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.70,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    // ── Field ─────────────────────────────────────────────
    final fieldPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF7CC94E), const Color(0xFF5AB034)],
          ).createShader(
            Rect.fromLTWH(
              0,
              size.height * 0.60,
              size.width,
              size.height * 0.40,
            ),
          );
    final fieldPath = Path()
      ..moveTo(0, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.55,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fieldPath, fieldPaint);

    // ── Crop rows ─────────────────────────────────────────
    _drawCropRows(canvas, size);

    // ── Dirt path ────────────────────────────────────────
    final roadPaint = Paint()
      ..color = const Color(0xFFCFB97E).withOpacity(0.55);
    final road = Path()
      ..moveTo(size.width * 0.28, size.height)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.72,
        size.width * 0.65,
        size.height,
      )
      ..close();
    canvas.drawPath(road, roadPaint);

    // ── Trees & house ─────────────────────────────────────
    _drawTree(canvas, Offset(size.width * 0.12, size.height * 0.55), 17);
    _drawTree(canvas, Offset(size.width * 0.88, size.height * 0.58), 15);
    _drawTree(canvas, Offset(size.width * 0.95, size.height * 0.62), 13);
    _drawHouse(canvas, Offset(size.width * 0.70, size.height * 0.52), size);

    // ── Tractor (movement logic unchanged) ───────────────
    final progress = (1 - math.cos(animationValue * math.pi * 2)) / 2;
    final leftLimit = size.width * 0.10;
    final rightLimit = size.width * 0.78;
    final tractorX = leftLimit + (rightLimit - leftLimit) * progress;
    final tractorY = size.height * 0.64 + math.sin(progress * math.pi) * 8;
    final movingRight = math.sin(animationValue * math.pi * 2) > 0;
    final tractorPos = Offset(tractorX, tractorY);

    _drawDust(canvas, tractorPos, animationValue, movingRight);
    _drawIrrigationSpray(canvas, tractorPos, animationValue, movingRight);
    _drawTractor(canvas, tractorPos, animationValue, movingRight);
  }

  // ── Sun with rays ─────────────────────────────────────────────────────────

  void _drawSun(Canvas canvas, Offset center, double t) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF176).withOpacity(0.35),
          const Color(0xFFFFF176).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 20));
    canvas.drawCircle(center, 20, glowPaint);

    final rayPaint = Paint()
      ..color = const Color(0xFFFDD835).withOpacity(0.7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final rayRotation = t * math.pi * 0.25; // slow spin
    for (int i = 0; i < 8; i++) {
      final angle = rayRotation + i * math.pi / 4;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * 10,
          center.dy + math.sin(angle) * 10,
        ),
        Offset(
          center.dx + math.cos(angle) * 17,
          center.dy + math.sin(angle) * 17,
        ),
        rayPaint,
      );
    }
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFFFDD835));
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFFFF59D));
  }

  // ── Drifting cloud ────────────────────────────────────────────────────────

  void _drawCloud(
    Canvas canvas,
    Size size,
    double t,
    double phaseOffset,
    double yFrac,
    double scaleFrac,
  ) {
    final cloudX =
        ((t + phaseOffset) % 1.0) * (size.width * 1.4) - size.width * 0.2;
    final cy = size.height * yFrac;
    final sc = size.width * scaleFrac;
    final p = Paint()..color = Colors.white.withOpacity(0.82);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cloudX, cy), width: sc, height: sc * 0.45),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cloudX - sc * 0.28, cy + 2),
        width: sc * 0.55,
        height: sc * 0.35,
      ),
      p,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cloudX + sc * 0.28, cy + 3),
        width: sc * 0.48,
        height: sc * 0.30,
      ),
      p,
    );
  }

  // ── Crop rows ─────────────────────────────────────────────────────────────

  void _drawCropRows(Canvas canvas, Size size) {
    final rowPaint = Paint()
      ..color = const Color(0xFF3D8C28).withOpacity(0.55)
      ..strokeWidth = 1.2;
    final plantPaint = Paint()
      ..color = const Color(0xFF5CAF3A).withOpacity(0.8);
    for (int row = 0; row < 6; row++) {
      final y = size.height * 0.76 + row * 5.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 22), rowPaint);
      // Small plant dots on each row
      for (double px = 6; px < size.width; px += 14) {
        final py = y - (px / size.width) * 22;
        canvas.drawCircle(Offset(px, py - 3), 2.2, plantPaint);
      }
    }
  }

  // ── Tree ──────────────────────────────────────────────────────────────────

  void _drawTree(Canvas canvas, Offset base, double height) {
    // Trunk
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 1.5, base.dy, 3, height),
      Paint()..color = const Color(0xFF8A5A2B),
    );
    // Shadow circle
    canvas.drawCircle(
      Offset(base.dx + 2, base.dy + 3),
      8.5,
      Paint()..color = const Color(0xFF2A8030).withOpacity(0.35),
    );
    // Canopy
    canvas.drawCircle(
      Offset(base.dx, base.dy - 4),
      10,
      Paint()..color = const Color(0xFF38B54A),
    );
    canvas.drawCircle(
      Offset(base.dx, base.dy - 7),
      7,
      Paint()..color = const Color(0xFF4AC85C),
    );
  }

  // ── House ─────────────────────────────────────────────────────────────────

  void _drawHouse(Canvas canvas, Offset pos, Size size) {
    final w = size.width * 0.13;
    final h = size.height * 0.18;
    // Wall
    canvas.drawRect(
      Rect.fromLTWH(pos.dx, pos.dy, w, h),
      Paint()..color = const Color(0xFFF6F3DC),
    );
    // Roof
    final roof = Path()
      ..moveTo(pos.dx - 4, pos.dy)
      ..lineTo(pos.dx + w / 2, pos.dy - 15)
      ..lineTo(pos.dx + w + 4, pos.dy)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF4CB653));
    // Door
    canvas.drawRect(
      Rect.fromLTWH(pos.dx + w * 0.43, pos.dy + h * 0.42, 8, h * 0.58),
      Paint()..color = const Color(0xFF8A5A2B),
    );
    // Window
    canvas.drawRect(
      Rect.fromLTWH(pos.dx + w * 0.12, pos.dy + h * 0.18, 9, 7),
      Paint()..color = const Color(0xFFB3E5FC),
    );
  }

  // ── Dust cloud ────────────────────────────────────────────────────────────

  void _drawDust(Canvas canvas, Offset pos, double t, bool movingRight) {
    for (int i = 0; i < 7; i++) {
      final wave = ((t * 5) + i * 0.18) % 1.0;
      final spread = movingRight ? -(wave * 26) - 6 : (wave * 26) + 44;
      final dx = pos.dx + spread;
      final dy = pos.dy + 16 + (i % 3) * 4 - wave * 6;
      final radius = 2.5 + wave * 7;
      canvas.drawCircle(
        Offset(dx, dy),
        radius,
        Paint()..color = const Color(0xFFD4B87A).withOpacity(0.22 * (1 - wave)),
      );
    }
  }

  // ── Irrigation spray ──────────────────────────────────────────────────────

  void _drawIrrigationSpray(
    Canvas canvas,
    Offset pos,
    double t,
    bool movingRight,
  ) {
    final sprayPaint = Paint()
      ..color = const Color(0xFF64B5F6).withOpacity(0.55)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    // Spray appears at the rear of the tractor
    final startX = movingRight ? pos.dx - 2 : pos.dx + 38;
    final baseY = pos.dy + 8;

    for (int i = 0; i < 5; i++) {
      final phase = ((t * 4) + i * 0.22) % 1.0;
      final len = 8 + phase * 10;
      final angle =
          (movingRight ? math.pi * 0.85 : math.pi * 0.15) + (i - 2) * 0.18;
      canvas.drawLine(
        Offset(startX, baseY),
        Offset(startX + math.cos(angle) * len, baseY + math.sin(angle) * len),
        sprayPaint,
      );
      // Droplet at tip
      canvas.drawCircle(
        Offset(startX + math.cos(angle) * len, baseY + math.sin(angle) * len),
        1.2,
        Paint()..color = const Color(0xFF42A5F5).withOpacity(0.6 * (1 - phase)),
      );
    }
  }

  // ── Tractor wrapper (movement logic unchanged) ────────────────────────────

  void _drawTractor(Canvas canvas, Offset pos, double t, bool movingRight) {
    canvas.save();
    if (movingRight) {
      canvas.translate(pos.dx + 42, 0);
      canvas.scale(-1, 1);
      _drawTractorBody(canvas, Offset(0, pos.dy), t, movingRight);
    } else {
      _drawTractorBody(canvas, pos, t, movingRight);
    }
    canvas.restore();
  }

  // ── Tractor body (enhanced, same bounce logic) ────────────────────────────

  void _drawTractorBody(Canvas canvas, Offset pos, double t, bool movingRight) {
    final bounce = math.sin(t * math.pi * 12) * 1.2;
    final base = pos + Offset(0, bounce);

    // === Chassis / body ===
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx, base.dy, 36, 15),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF2E9C38),
    );
    // Body side highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx + 1, base.dy + 1, 34, 4),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF4DBF5A).withOpacity(0.5),
    );

    // === Cab ===
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx + 20, base.dy - 15, 18, 17),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF247A2E),
    );
    // Cab roof highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx + 21, base.dy - 14, 16, 3),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF3AAF46).withOpacity(0.55),
    );

    // === Windshield (glass) ===
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx + 22, base.dy - 12, 12, 8),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFB3E5FC).withOpacity(0.75),
    );
    // Glass glare
    canvas.drawLine(
      Offset(base.dx + 23, base.dy - 11),
      Offset(base.dx + 26, base.dy - 8),
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );

    // === Driver silhouette ===
    canvas.drawCircle(
      Offset(base.dx + 27, base.dy - 10),
      3.5,
      Paint()..color = const Color(0xFF5D4037).withOpacity(0.85),
    );

    // === Hood / engine cover ===
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx + 3, base.dy + 2, 15, 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1E7A27),
    );
    // Hood stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx + 4, base.dy + 2, 13, 2),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFFF7C948).withOpacity(0.7),
    );

    // === Exhaust pipe ===
    canvas.drawLine(
      Offset(base.dx + 5, base.dy),
      Offset(base.dx + 5, base.dy - 14),
      Paint()
        ..color = const Color(0xFF333333)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // Exhaust smoke puffs
    for (int i = 0; i < 3; i++) {
      final phase = ((t * 3) + i * 0.35) % 1.0;
      final sy = base.dy - 14 - phase * 14;
      final sr = 1.5 + phase * 3.5;
      canvas.drawCircle(
        Offset(base.dx + 5 + phase * 4, sy),
        sr,
        Paint()
          ..color = const Color(0xFF888888).withOpacity(0.30 * (1 - phase)),
      );
    }

    // === Headlight ===
    canvas.drawCircle(
      Offset(base.dx + 1.5, base.dy + 5),
      2.5,
      Paint()..color = const Color(0xFFFFF176),
    );
    // Headlight glow
    canvas.drawCircle(
      Offset(base.dx + 1.5, base.dy + 5),
      4.5,
      Paint()..color = const Color(0xFFFFF9C4).withOpacity(0.25),
    );

    // === Wheels ===
    final smallWheel = Offset(base.dx + 8, base.dy + 18);
    final bigWheel = Offset(base.dx + 32, base.dy + 18);

    _drawWheel(canvas, smallWheel, 9, t, movingRight);
    _drawWheel(canvas, bigWheel, 11, t, movingRight);

    // === Rear hitch / sprayer arm ===
    canvas.drawLine(
      Offset(base.dx + 36, base.dy + 10),
      Offset(base.dx + 42, base.dy + 10),
      Paint()
        ..color = const Color(0xFF555555)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRect(
      Rect.fromLTWH(base.dx + 40, base.dy + 7, 5, 6),
      Paint()..color = const Color(0xFF757575),
    );
  }

  // ── Detailed wheel with tread ─────────────────────────────────────────────

  void _drawWheel(
    Canvas canvas,
    Offset center,
    double radius,
    double t,
    bool movingRight,
  ) {
    final rotation = movingRight ? t * math.pi * 8 : -t * math.pi * 8;

    // Tire
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF1A1A1A));
    // Tire sidewall detail
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF3A3A3A),
    );
    // Hub
    canvas.drawCircle(
      center,
      radius * 0.42,
      Paint()..color = const Color(0xFFD0D0D0),
    );
    canvas.drawCircle(
      center,
      radius * 0.22,
      Paint()..color = const Color(0xFFB0B0B0),
    );

    // Spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final angle = rotation + i * math.pi * 2 / 5;
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * radius * 0.38,
          center.dy + math.sin(angle) * radius * 0.38,
        ),
        spokePaint,
      );
    }

    // Tread lugs
    final lugPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.butt;
    for (int i = 0; i < 8; i++) {
      final angle = rotation + i * math.pi / 4;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * (radius - 2),
          center.dy + math.sin(angle) * (radius - 2),
        ),
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
        lugPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FarmPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ── Paddy painter (crop card thumbnail) ──────────────────────────────────────

class PaddyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFA9E063), Color(0xFF4CAD34)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final grassPaint = Paint()
      ..color = const Color(0xFFE5F58A)
      ..strokeWidth = 1.4;
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + 5, size.height * 0.25),
        grassPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
