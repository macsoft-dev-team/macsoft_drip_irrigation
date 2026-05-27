import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_device.dart';
import '../models/app_user.dart';
import '../services/app_state.dart';
import 'telemetry_page.dart';
import 'command_page.dart';
import 'device_config_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'all'; // all | active | inactive

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ApiDevice> _filter(List<ApiDevice> devices) {
    final q = _search.trim().toLowerCase();
    return devices.where((d) {
      final matchSearch =
          q.isEmpty ||
          d.imeinumber.toLowerCase().contains(q) ||
          (d.name ?? '').toLowerCase().contains(q);
      final matchStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'active' && d.isActive) ||
          (_statusFilter == 'inactive' && !d.isActive);
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, __) {
        final isAdmin =
            state.user?.role == UserRole.admin ||
            state.user?.role == UserRole.superadmin;
        final filtered = _filter(state.devices);

        return Column(
          children: [
            // ── Search + Filter bar ──────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search IMEI or name…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _statusFilter == 'all',
                          onTap: () => setState(() => _statusFilter = 'all'),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Active',
                          selected: _statusFilter == 'active',
                          color: const Color(0xFF10B981),
                          onTap: () => setState(() => _statusFilter = 'active'),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Offline',
                          selected: _statusFilter == 'inactive',
                          color: const Color(0xFF9CA3AF),
                          onTap: () =>
                              setState(() => _statusFilter = 'inactive'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── List ─────────────────────────────────────────────
            Expanded(
              child: state.devicesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.devicesError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.devicesError!,
                            style: const TextStyle(color: Color(0xFFEF4444)),
                          ),
                          TextButton(
                            onPressed: state.loadDevices,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: state.loadDevices,
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No devices found',
                                style: TextStyle(color: Color(0xFF9CA3AF)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _DeviceRow(
                                device: filtered[i],
                                isAdmin: isAdmin,
                                onTelemetry: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TelemetryPage(device: filtered[i]),
                                  ),
                                ),
                                onCommand: isAdmin
                                    ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CommandPage(device: filtered[i]),
                                        ),
                                      )
                                    : null,
                                onConfig: isAdmin
                                    ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DeviceConfigPage(
                                            device: filtered[i],
                                          ),
                                        ),
                                      )
                                    : null,
                                onPayload: () =>
                                    _showPayloadSheet(context, filtered[i]),
                              ),
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showPayloadSheet(BuildContext context, ApiDevice device) {
    final payload = device.telemetryLogs.isNotEmpty
        ? device.telemetryLogs.first.payload
        : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayloadSheet(imei: device.imeinumber, payload: payload),
    );
  }
}

// ── Raw Payload bottom sheet ──────────────────────────────────────────────────

class _PayloadSheet extends StatelessWidget {
  final String imei;
  final Map<String, dynamic>? payload;
  const _PayloadSheet({required this.imei, this.payload});

  @override
  Widget build(BuildContext context) {
    final encoder = const JsonEncoder.withIndent('  ');
    final jsonText = payload != null && payload!.isNotEmpty
        ? encoder.convert(payload)
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: const Icon(
                      Icons.data_object_rounded,
                      size: 16,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Raw Payload',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        Text(
                          imei,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xFF9CA3AF),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            // body
            Expanded(
              child: jsonText != null
                  ? SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SelectableText(
                          jsonText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF334155),
                            height: 1.6,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No payload received yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
            ),
            // close button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STS fault bitmask helpers ────────────────────────────────────────────────

class _FaultBit {
  final int bit;
  final String label;
  final Color color;
  final Color bgColor;
  const _FaultBit(this.bit, this.label, this.color, this.bgColor);
}

const _stsFaults = [
  _FaultBit(0, 'Phase Fault', Color(0xFFDC2626), Color(0xFFFEF2F2)),
  _FaultBit(1, 'Overcurrent', Color(0xFFEA580C), Color(0xFFFFF7ED)),
  _FaultBit(2, 'Overvoltage', Color(0xFFB45309), Color(0xFFFFFBEB)),
  _FaultBit(3, 'Undervoltage', Color(0xFFCA8A04), Color(0xFFFEFCE8)),
];

List<_FaultBit> _getFaults(dynamic sts) {
  if (sts == null) return [];
  final v = (sts as num).toInt();
  if (v == 0) return [];
  return _stsFaults.where((f) => (v >> f.bit) & 1 == 1).toList();
}

// ── Device row card ────────────────────────────────────────────────────────

class _DeviceRow extends StatelessWidget {
  final ApiDevice device;
  final bool isAdmin;
  final VoidCallback onTelemetry;
  final VoidCallback? onCommand;
  final VoidCallback? onConfig;
  final VoidCallback onPayload;

  const _DeviceRow({
    required this.device,
    required this.isAdmin,
    required this.onTelemetry,
    this.onCommand,
    this.onConfig,
    required this.onPayload,
  });

  static String _formatTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  static String _clockTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final latest = device.telemetryLogs.isNotEmpty
        ? device.telemetryLogs.first
        : null;
    final faults = latest != null ? _getFaults(latest.sts) : <_FaultBit>[];
    final rmd = device.config?['rmd'];
    final hasUser = device.user != null;

    return GestureDetector(
      onTap: onTelemetry,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: device.isActive
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: device.isActive
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.router_rounded,
                    size: 18,
                    color: device.isActive
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
                        device.name ?? '—',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.imeinumber,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          if (rmd != null)
                            _ModeBadge(auto: (rmd as num).toInt() == 1),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(active: device.isActive),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF8FAFC)),
            const SizedBox(height: 10),

            // ── Telemetry block ──────────────────────────
            if (latest != null) ...[
              // Fault badges
              if (faults.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: faults
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: f.bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: f.color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '⚠ ${f.label}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: f.color,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],

              // Voltage
              Text(
                'Voltage (V)',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF60A5FA),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _TeleStat(
                      label: 'Ph 1',
                      value: latest.iv1 != null
                          ? latest.iv1!.toStringAsFixed(1)
                          : '—',
                      color: _TeleColor.blue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _TeleStat(
                      label: 'Ph 2',
                      value: latest.iv2 != null
                          ? latest.iv2!.toStringAsFixed(1)
                          : '—',
                      color: _TeleColor.blue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _TeleStat(
                      label: 'Ph 3',
                      value: latest.iv3 != null
                          ? latest.iv3!.toStringAsFixed(1)
                          : '—',
                      color: _TeleColor.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Current
              Text(
                'Current (A)',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFBBF24),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _TeleStat(
                      label: 'Ph 1',
                      value: latest.ic1 != null
                          ? latest.ic1!.toStringAsFixed(2)
                          : '—',
                      color: _TeleColor.amber,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _TeleStat(
                      label: 'Ph 2',
                      value: latest.ic2 != null
                          ? latest.ic2!.toStringAsFixed(2)
                          : '—',
                      color: _TeleColor.amber,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _TeleStat(
                      label: 'Ph 3',
                      value: latest.ic3 != null
                          ? latest.ic3!.toStringAsFixed(2)
                          : '—',
                      color: _TeleColor.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Footer: user + last data time
              Row(
                children: [
                  if (hasUser) ...[
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        device.user!.displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (latest.time != null) ...[
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _clockTime(latest.time!),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(latest.time!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              // No telemetry yet
              Row(
                children: [
                  if (hasUser) ...[
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.user!.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasUser) const SizedBox(height: 6),
              const Center(
                child: Text(
                  'No telemetry yet',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Action buttons ───────────────────────────
            Row(
              children: [
                _ActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Telemetry',
                  color: const Color(0xFF1565C0),
                  onTap: onTelemetry,
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.data_object_rounded,
                  label: 'Payload',
                  color: const Color(0xFF7C3AED),
                  onTap: onPayload,
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.terminal_rounded,
                    label: 'Command',
                    color: const Color(0xFF6D28D9),
                    onTap: onCommand ?? () {},
                  ),
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.settings_rounded,
                    label: 'Config',
                    color: const Color(0xFF0D9488),
                    onTap: onConfig ?? () {},
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Offline',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color = const Color(0xFF1565C0),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ── Mode badge (Auto / Manual from RMD) ──────────────────────────────────────

class _ModeBadge extends StatelessWidget {
  final bool auto;
  const _ModeBadge({required this.auto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: auto ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: auto ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Text(
        auto ? 'Auto' : 'Manual',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: auto ? const Color(0xFF059669) : const Color(0xFFB45309),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Telemetry stat cell ───────────────────────────────────────────────────────

enum _TeleColor { blue, amber }

class _TeleStat extends StatelessWidget {
  final String label;
  final String value;
  final _TeleColor color;
  const _TeleStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (color) {
      _TeleColor.blue => (
        const Color(0xFFEFF6FF),
        const Color(0xFFBFDBFE),
        const Color(0xFF1D4ED8),
      ),
      _TeleColor.amber => (
        const Color(0xFFFFFBEB),
        const Color(0xFFFDE68A),
        const Color(0xFFB45309),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: fg.withValues(alpha: 0.6),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
