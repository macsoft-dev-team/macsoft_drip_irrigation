import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_device.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../services/socket_service.dart';
import '../widgets/stat_card.dart';
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

  Widget _buildOverview(AppState state) {
    final devices = state.devices;
    final onlineCount = devices.where((d) => d.isActive).length;
    final user = state.user;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return RefreshIndicator(
      onRefresh: state.loadDevices,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
        children: [
          Text(
            greeting,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            user?.name ?? 'System Overview',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1F36),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Devices',
                  value: '${devices.length}',
                  icon: Icons.devices_rounded,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Active',
                  value: '$onlineCount',
                  icon: Icons.wifi_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Offline',
                  value: '${devices.length - onlineCount}',
                  icon: Icons.wifi_off_rounded,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionHeader(title: 'Recent Devices'),
          const SizedBox(height: 10),
          if (state.devicesLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.devicesError != null)
            _ErrorTile(message: state.devicesError!, onRetry: state.loadDevices)
          else
            ...devices.take(8).map((d) => _DeviceSummaryTile(device: d)),
        ],
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
        builder: (context, state, _) => _buildOverview(state),
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
          _buildOverview(state),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1F36),
        letterSpacing: -0.2,
      ),
    );
  }
}

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
