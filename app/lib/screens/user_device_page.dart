import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/api_device.dart';
import '../services/app_state.dart';
import '../services/socket_service.dart';
import 'command_page.dart';
import 'device_config_page.dart';

// ── STS Fault bitmask ────────────────────────────────────────────────────────

class _FaultDef {
  final int bit;
  final String label;
  final bool isRed;
  const _FaultDef(this.bit, this.label, this.isRed);
}

const _faultDefs = [
  _FaultDef(0, 'Phase Fault', true),
  _FaultDef(1, 'Overcurrent', true),
  _FaultDef(2, 'Overvoltage', false),
  _FaultDef(3, 'Undervoltage', false),
];

List<_FaultDef> _decodeFaults(dynamic sts) {
  final v = (sts as num?)?.toInt() ?? 0;
  if (v == 0) return [];
  return _faultDefs.where((f) => (v >> f.bit) & 1 == 1).toList();
}

// ── Main Page ────────────────────────────────────────────────────────────────

class UserDevicePage extends StatefulWidget {
  final ApiDevice device;
  const UserDevicePage({super.key, required this.device});

  @override
  State<UserDevicePage> createState() => _UserDevicePageState();
}

class _UserDevicePageState extends State<UserDevicePage> {
  late ApiDevice _device;
  bool _cmdLoading = false;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
    SocketService.instance.addListener(_onTelemetry);
  }

  @override
  void dispose() {
    SocketService.instance.removeListener(_onTelemetry);
    super.dispose();
  }

  void _onTelemetry(String deviceId, TelemetryRow row) {
    if (deviceId != _device.id) return;
    setState(
      () => _device = _device.copyWith(isActive: true, telemetryLogs: [row]),
    );
    context.read<AppState>().updateDeviceLive(deviceId, row);
  }

  TelemetryRow? get _latest =>
      _device.telemetryLogs.isNotEmpty ? _device.telemetryLogs.first : null;

  List<_FaultDef> get _faults => _decodeFaults(_latest?.sts);
  bool get _isAuto => (_device.config?['rmd'] as num?)?.toInt() == 1;
  bool get _is3Phase => (_device.config?['pmd'] as num?)?.toInt() != 1;
  bool get _motorRunning =>
      _device.isActive &&
      _faults.isEmpty &&
      (_latest?.amm as num?)?.toInt() == 1;

  Future<void> _handleAction(
    Map<String, dynamic> payload, {
    Map<String, dynamic>? configPatch,
  }) async {
    if (_cmdLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _cmdLoading = true);
    try {
      final api = context.read<AppState>().api;
      if (api == null) return;
      await api.sendCommand(_device.id, payload);
      if (configPatch != null) {
        // Save config using uppercase MQTT keys (backend mqttToDb expects them)
        await api.saveDeviceConfig(_device.id, payload);
        final newCfg = Map<String, dynamic>.from(_device.config ?? {})
          ..addAll(configPatch);
        setState(() => _device = _device.copyWith(config: newCfg));
        if (mounted)
          context.read<AppState>().updateDeviceConfig(_device.id, newCfg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Command failed: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cmdLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latest;
    final faults = _faults;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: const Color(0x18000000),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _device.name ?? 'Industrial Gateway',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1F36),
              ),
            ),
            Text(
              'ID: ${_device.imeinumber}',
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          _LiveBadge(isActive: _device.isActive),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // ── Connection Metadata ────────────────────────────────
            _MetaRow(latest: latest),
            const SizedBox(height: 14),

            // ── Phase Telemetry Cards ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PhaseCard(label: 'R', v: latest?.iv1, i: latest?.ic1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PhaseCard(label: 'S', v: latest?.iv2, i: latest?.ic2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PhaseCard(label: 'T', v: latest?.iv3, i: latest?.ic3),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Control Block ──────────────────────────────────────
            _ControlCard(
              isAuto: _isAuto,
              is3Phase: _is3Phase,
              motorRunning: _motorRunning,
              cmdLoading: _cmdLoading,
              // val = new is3Phase value
              onToggleTopology: (val) => _handleAction(
                {'PMD': val ? 0 : 1},
                configPatch: {'pmd': val ? 0 : 1},
              ),
              onTogglePower: (val) => _handleAction({'PWR': val ? 1 : 0}),
              // val = new isAuto value
              onToggleLogic: (val) => _handleAction(
                {'RMD': val ? 1 : 0},
                configPatch: {'rmd': val ? 1 : 0},
              ),
            ),
            const SizedBox(height: 14),

            // ── Timers ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _TimerCard(
                    label: 'Run Schedule',
                    value: (_device.config?['ont'] as num?)?.toInt() ?? 0,
                    color: const Color(0xFF10B981),
                    icon: Icons.loop_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimerCard(
                    label: 'Idle Timeout',
                    value: (_device.config?['oft'] as num?)?.toInt() ?? 0,
                    color: const Color(0xFFF59E0B),
                    icon: Icons.timer_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Fault Monitor ──────────────────────────────────────
            _FaultCard(
              faults: faults,
              cmdLoading: _cmdLoading,
              onClearFaults: () => _handleAction({'CLR': 1}),
            ),
          ],
        ),
      ),

      // ── Bottom Action Bar ──────────────────────────────────────
      bottomNavigationBar: _BottomActionBar(
        device: _device,
        onRaw: () => _showRawPayload(context, latest?.payload),
      ),
    );
  }

  void _showRawPayload(BuildContext context, Map<String, dynamic>? payload) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Raw Payload',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  child: payload == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No payload received yet',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            const JsonEncoder.withIndent('  ').convert(payload),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF334155),
                              height: 1.6,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  final bool isActive;
  const _LiveBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Live' : 'Offline',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final TelemetryRow? latest;
  const _MetaRow({this.latest});

  String _fmtTime(DateTime? t) {
    if (t == null) return 'Waiting...';
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.signal_cellular_alt_rounded,
            size: 14,
            color: Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Signal Strength',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              latest?.rsi != null
                  ? '${latest!.rsi!.toStringAsFixed(0)} dBm'
                  : '--',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Last Sync',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _fmtTime(latest?.time),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            size: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final String label;
  final double? v;
  final double? i;
  const _PhaseCard({required this.label, this.v, this.i});

  String _fmt(double? val, int dec) =>
      val != null ? val.toStringAsFixed(dec) : '—';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$label Phase',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(v, 0),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1F36),
              height: 1,
            ),
          ),
          const Text(
            'V',
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),
          Text(
            _fmt(i, 1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF475569),
              height: 1,
            ),
          ),
          const Text(
            'A',
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final bool isAuto;
  final bool is3Phase;
  final bool motorRunning;
  final bool cmdLoading;
  final ValueChanged<bool> onToggleTopology; // receives new is3Phase
  final ValueChanged<bool> onTogglePower; // receives new isOn
  final ValueChanged<bool> onToggleLogic; // receives new isAuto

  const _ControlCard({
    required this.isAuto,
    required this.is3Phase,
    required this.motorRunning,
    required this.cmdLoading,
    required this.onToggleTopology,
    required this.onTogglePower,
    required this.onToggleLogic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Topology toggle
              Column(
                children: [
                  const Text(
                    'Topology',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _HSlideToggle(
                    leftLabel: '3PH',
                    rightLabel: '2PH',
                    isRight: !is3Phase,
                    enabled: !cmdLoading,
                    onChanged: (isRight) => onToggleTopology(!isRight),
                  ),
                ],
              ),

              // Power button
              _PowerButton(
                isOn: motorRunning,
                loading: cmdLoading,
                onToggle: onTogglePower,
              ),

              // Logic toggle
              Column(
                children: [
                  const Text(
                    'Logic',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _HSlideToggle(
                    leftLabel: 'AUTO',
                    rightLabel: 'MAN',
                    isRight: !isAuto,
                    enabled: !cmdLoading,
                    onChanged: (isRight) => onToggleLogic(!isRight),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: motorRunning
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: motorRunning
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: motorRunning
                        ? const Color(0xFF10B981)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  motorRunning ? 'SYSTEM RUNNING' : 'SYSTEM STANDBY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: motorRunning
                        ? const Color(0xFF059669)
                        : const Color(0xFF64748B),
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

class _HSlideToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isRight;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _HSlideToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isRight,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => onChanged(!isRight) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 78,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                left: isRight ? 40 : 2,
                top: 2,
                bottom: 2,
                child: Container(
                  width: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isRight ? rightLabel : leftLabel,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2563EB),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: isRight
                            ? Text(
                                leftLabel,
                                style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: !isRight
                            ? Text(
                                rightLabel,
                                style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  final bool isOn;
  final bool loading;
  final ValueChanged<bool> onToggle;

  const _PowerButton({
    required this.isOn,
    required this.loading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : () => onToggle(!isOn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? const Color(0xFF10B981) : Colors.white,
          border: Border.all(
            color: isOn ? const Color(0xFF6EE7B7) : const Color(0xFFF1F5F9),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: isOn
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: isOn ? Colors.white : const Color(0xFFD1D5DB),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 52,
                    color: isOn ? Colors.white : const Color(0xFFD1D5DB),
                  ),
                  Text(
                    isOn ? 'STOP' : 'START',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isOn ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _TimerCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$value',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      const TextSpan(
                        text: ' min',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
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

class _FaultCard extends StatelessWidget {
  final List<_FaultDef> faults;
  final bool cmdLoading;
  final VoidCallback onClearFaults;

  const _FaultCard({
    required this.faults,
    required this.cmdLoading,
    required this.onClearFaults,
  });

  @override
  Widget build(BuildContext context) {
    final hasF = faults.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: hasF
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                const Text(
                  'DIAGNOSTICS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: cmdLoading ? null : onClearFaults,
                  child: Opacity(
                    opacity: cmdLoading ? 0.5 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.refresh_rounded,
                            size: 11,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Reset Faults',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: hasF
                ? Column(
                    children: faults
                        .map(
                          (f) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: f.isRed
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: f.isRed
                                    ? const Color(0xFFFECACA)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: f.isRed
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${f.label} Detected',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: f.isRed
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFFB45309),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'System Healthy — No active faults',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final ApiDevice device;
  final VoidCallback onRaw;

  const _BottomActionBar({required this.device, required this.onRaw});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.settings_rounded,
            label: 'Config',
            color: const Color(0xFF10B981),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeviceConfigPage(device: device),
              ),
            ),
          ),
          const _VDivider(),
          _ActionBtn(
            icon: Icons.data_object_rounded,
            label: 'Raw',
            color: const Color(0xFF7C3AED),
            onTap: onRaw,
          ),
          const _VDivider(),
          _ActionBtn(
            icon: Icons.terminal_rounded,
            label: 'Debug',
            color: const Color(0xFF2563EB),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommandPage(device: device)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFFE2E8F0));
  }
}
