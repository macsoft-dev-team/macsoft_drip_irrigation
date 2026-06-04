import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_device.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';

// ── DEFAULT_CONFIG mirrors JS DEFAULT_CONFIG exactly ───────────────────────
const Map<String, double> _defaultCfg = {
  '3LV': 180,
  '3HV': 260,
  '3DR': 10.5,
  '3OL': 15.0,
  '2LV': 180,
  '2HV': 260,
  '2DR': 9.5,
  '2OL': 14.0,
  'RMD': 1,
  'PMD': 0,
  'ONT': 30,
  'OFT': 15,
  'CRS': 0,
  'ON1': 6.30,
  'OF1': 7.00,
  'ON2': 12.00,
  'OF2': 12.30,
  'ON3': 18.00,
  'OF3': 18.30,
  'ON4': 20.00,
  'OF4': 20.30,
  'ON5': 22.00,
  'OF5': 22.30,
  'CTS': 0,
};

/// Maps DB field names (lv3 / off1 …) → MQTT payload keys (3LV / OF1 …)
Map<String, double> _dbToCfg(Map<String, dynamic> db) => {
  '3LV': _d(db['lv3'], _defaultCfg['3LV']!),
  '3HV': _d(db['hv3'], _defaultCfg['3HV']!),
  '3DR': _d(db['dr3'], _defaultCfg['3DR']!),
  '3OL': _d(db['ol3'], _defaultCfg['3OL']!),
  '2LV': _d(db['lv2'], _defaultCfg['2LV']!),
  '2HV': _d(db['hv2'], _defaultCfg['2HV']!),
  '2DR': _d(db['dr2'], _defaultCfg['2DR']!),
  '2OL': _d(db['ol2'], _defaultCfg['2OL']!),
  'RMD': _d(db['rmd'], _defaultCfg['RMD']!),
  'PMD': _d(db['pmd'], _defaultCfg['PMD']!),
  'ONT': _d(db['ont'], _defaultCfg['ONT']!),
  'OFT': _d(db['oft'], _defaultCfg['OFT']!),
  'CRS': _d(db['crs'], _defaultCfg['CRS']!),
  'ON1': _d(db['on1'], _defaultCfg['ON1']!),
  'OF1': _d(db['off1'], _defaultCfg['OF1']!),
  'ON2': _d(db['on2'], _defaultCfg['ON2']!),
  'OF2': _d(db['off2'], _defaultCfg['OF2']!),
  'ON3': _d(db['on3'], _defaultCfg['ON3']!),
  'OF3': _d(db['off3'], _defaultCfg['OF3']!),
  'ON4': _d(db['on4'], _defaultCfg['ON4']!),
  'OF4': _d(db['off4'], _defaultCfg['OF4']!),
  'ON5': _d(db['on5'], _defaultCfg['ON5']!),
  'OF5': _d(db['off5'], _defaultCfg['OF5']!),
  'CTS': _d(db['cts'], _defaultCfg['CTS']!),
};

double _d(dynamic v, double fallback) =>
    v != null ? (v as num).toDouble() : fallback;

// ──────────────────────────────────────────────────────────────────────────────

class DeviceConfigPage extends StatefulWidget {
  final ApiDevice device;
  const DeviceConfigPage({super.key, required this.device});

  @override
  State<DeviceConfigPage> createState() => _DeviceConfigPageState();
}

class _DeviceConfigPageState extends State<DeviceConfigPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // ── Device Info state ────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  String? _selectedUserId;
  List<AppUser> _userOptions = [];
  bool _usersLoading = false;
  bool _infoSaving = false;
  String? _infoError;

  // ── Motor Config state ───────────────────────────────────────────────────
  late Map<String, double> _cfg;
  // TextControllers for numeric fields only (not toggle fields)
  late final Map<String, TextEditingController> _ctrl;
  bool _configSaving = false;
  bool _configSending = false;
  String? _configError;

  static const _numericKeys = [
    '3LV',
    '3HV',
    '3DR',
    '3OL',
    '2LV',
    '2HV',
    '2DR',
    '2OL',
    'ONT',
    'OFT',
    'ON1',
    'OF1',
    'ON2',
    'OF2',
    'ON3',
    'OF3',
    'ON4',
    'OF4',
    'ON5',
    'OF5',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _nameCtrl.text = widget.device.name ?? '';
    _selectedUserId = widget.device.userId;
    _initCfg();
    _loadUserOptions();
  }

  void _initCfg() {
    final db = widget.device.config;
    _cfg = db != null ? _dbToCfg(db) : Map.of(_defaultCfg);
    _ctrl = {
      for (final k in _numericKeys)
        k: TextEditingController(text: _cfg[k]!.toString()),
    };
  }

  void _set(String key, double val) => setState(() => _cfg[key] = val);

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── User options for Device Info ─────────────────────────────────────────
  Future<void> _loadUserOptions() async {
    final token = context.read<AppState>().token;
    if (token == null) return;
    setState(() => _usersLoading = true);
    try {
      final list = await ApiService(token: token).getUserOptions();
      if (!mounted) return;
      setState(() {
        _userOptions = list;
        _usersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _usersLoading = false);
    }
  }

  // ── Save Device Info ─────────────────────────────────────────────────────
  Future<void> _saveInfo() async {
    final token = context.read<AppState>().token;
    if (token == null) return;
    setState(() {
      _infoSaving = true;
      _infoError = null;
    });
    try {
      await ApiService(token: token).updateDevice(widget.device.id, {
        'name': _nameCtrl.text.trim(),
        if (_selectedUserId != null) 'userId': _selectedUserId,
      });
      if (!mounted) return;
      setState(() => _infoSaving = false);
      await context.read<AppState>().loadDevices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device info saved'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _infoSaving = false;
        _infoError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Build MQTT payload from current state ────────────────────────────────
  Map<String, dynamic> _buildPayload() {
    // Flush text controllers into _cfg
    for (final k in _numericKeys) {
      _cfg[k] = double.tryParse(_ctrl[k]!.text) ?? _cfg[k]!;
    }
    return {for (final e in _cfg.entries) e.key: e.value};
  }

  // ── Save config to DB ────────────────────────────────────────────────────
  Future<void> _saveConfig() async {
    final token = context.read<AppState>().token;
    if (token == null) return;
    setState(() {
      _configSaving = true;
      _configError = null;
    });
    try {
      await ApiService(
        token: token,
      ).saveDeviceConfig(widget.device.id, _buildPayload());
      if (!mounted) return;
      setState(() => _configSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Config saved'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _configSaving = false;
        _configError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Send config to device via MQTT command ───────────────────────────────
  Future<void> _sendToDevice() async {
    final token = context.read<AppState>().token;
    if (token == null) return;
    setState(() {
      _configSending = true;
      _configError = null;
    });
    try {
      await ApiService(
        token: token,
      ).sendCommand(widget.device.id, _buildPayload());
      if (!mounted) return;
      setState(() => _configSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Config sent to device'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _configSending = false;
        _configError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1F36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.device.name ?? widget.device.imeinumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
            Text(
              'Configuration',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF059669),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFF059669),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Motor Config'),
            Tab(text: 'Device Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildMotorTab(), _buildInfoTab()],
      ),
    );
  }

  // ── Device Info tab ───────────────────────────────────────────────────────
  Widget _buildInfoTab() {
    final user = context.watch<AppState>().user;
    final isAdmin = user?.isAdmin ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Info',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 16),
            // IMEI — read-only
            _LabeledField(
              label: 'IMEI Number',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.device.imeinumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'IMEI cannot be changed.',
              style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: 'Device Name',
              child: TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter device name…',
                ),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Assigned Customer',
                child: _usersLoading
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _userOptions.any((u) => u.id == _selectedUserId)
                            ? _selectedUserId
                            : null,
                        isExpanded: true,
                        itemHeight: null,
                        decoration: const InputDecoration(
                          hintText: 'Select user',
                        ),
                        selectedItemBuilder: (context) => [
                          const Text(
                            '— Unassigned —',
                            overflow: TextOverflow.ellipsis,
                          ),
                          ..._userOptions.map(
                            (u) => Text(
                              u.name ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('— Unassigned —'),
                          ),
                          ..._userOptions.map(
                            (u) => DropdownMenuItem(
                              value: u.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    u.name ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (u.email != null)
                                    Text(
                                      u.email!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedUserId = v),
                      ),
              ),
            ],
            if (_infoError != null) ...[
              const SizedBox(height: 12),
              Text(
                _infoError!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _infoSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 16),
                label: Text(_infoSaving ? 'Saving…' : 'Save Changes'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _infoSaving ? null : _saveInfo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Motor Config tab ──────────────────────────────────────────────────────
  Widget _buildMotorTab() {
    final isBusy = _configSaving || _configSending;
    final showSchedules = _cfg['CRS']!.round() == 1;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                // ── Operation Mode ────────────────────────────────
                _Section(
                  title: 'Operation Mode',
                  color: const Color(0xFF059669),
                  icon: Icons.bolt_rounded,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToggleField(
                          label: 'Run Mode (RMD)',
                          fieldKey: 'RMD',
                          cfg: _cfg,
                          options: const [(0, 'Manual'), (1, 'Auto')],
                          onChanged: _set,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ToggleField(
                          label: 'Phase Mode (PMD)',
                          fieldKey: 'PMD',
                          cfg: _cfg,
                          options: const [(0, '3-Phase'), (1, '2-Phase')],
                          onChanged: _set,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── 3-Phase Protection ────────────────────────────
                _Section(
                  title: '3-Phase Protection',
                  color: const Color(0xFF2563EB),
                  icon: Icons.shield_rounded,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _NumField(
                              label: 'Low Voltage — 3LV (V)',
                              ctrl: _ctrl['3LV']!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumField(
                              label: 'High Voltage — 3HV (V)',
                              ctrl: _ctrl['3HV']!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _NumField(
                              label: 'Dry Run — 3DR (A)',
                              ctrl: _ctrl['3DR']!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumField(
                              label: 'Overload — 3OL (A)',
                              ctrl: _ctrl['3OL']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── 2-Phase Protection ────────────────────────────
                _Section(
                  title: '2-Phase Protection',
                  color: const Color(0xFFD97706),
                  icon: Icons.shield_rounded,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _NumField(
                              label: 'Low Voltage — 2LV (V)',
                              ctrl: _ctrl['2LV']!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumField(
                              label: 'High Voltage — 2HV (V)',
                              ctrl: _ctrl['2HV']!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _NumField(
                              label: 'Dry Run — 2DR (A)',
                              ctrl: _ctrl['2DR']!,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NumField(
                              label: 'Overload — 2OL (A)',
                              ctrl: _ctrl['2OL']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Timer ─────────────────────────────────────────
                _Section(
                  title: 'Timer',
                  color: const Color(0xFF059669),
                  icon: Icons.timer_rounded,
                  child: Row(
                    children: [
                      Expanded(
                        child: _NumField(
                          label: 'ON Time — ONT (min)',
                          ctrl: _ctrl['ONT']!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumField(
                          label: 'OFF Time — OFT (min)',
                          ctrl: _ctrl['OFT']!,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Control & Counter ─────────────────────────────
                _Section(
                  title: 'Control & Counter',
                  color: const Color(0xFF0284C7),
                  icon: Icons.tune_rounded,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ToggleField(
                          label: 'Control Mode (CRS)',
                          fieldKey: 'CRS',
                          cfg: _cfg,
                          options: const [(0, 'Cycle'), (1, 'RTC')],
                          onChanged: _set,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ToggleField(
                          label: 'Counter (CTS)',
                          fieldKey: 'CTS',
                          cfg: _cfg,
                          options: const [(0, 'Reset'), (1, 'Hold')],
                          onChanged: _set,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── RTC Schedules (CRS = 1 only) ──────────────────
                if (showSchedules) ...[
                  _Section(
                    title: 'RTC Schedules (HH.MM)',
                    color: const Color(0xFF6366F1),
                    icon: Icons.schedule_rounded,
                    child: Column(
                      children: List.generate(5, (i) {
                        final n = i + 1;
                        return Padding(
                          padding: EdgeInsets.only(bottom: i < 4 ? 12 : 0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Schedule $n',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF9CA3AF),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _NumField(
                                        label: 'Start — ON$n',
                                        ctrl: _ctrl['ON$n']!,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _NumField(
                                        label: 'Stop — OF$n',
                                        ctrl: _ctrl['OF$n']!,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_configError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _configError!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Footer: Save + Send to Device ─────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.device.mqttCmdTopic != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.device.mqttCmdTopic!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFCBD5E1),
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: isBusy && _configSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 16),
                      label: Text(_configSaving ? 'Saving…' : 'Save'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: isBusy ? null : _saveConfig,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: isBusy && _configSending
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(
                        _configSending ? 'Sending…' : 'Send to Device',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: isBusy ? null : _sendToDevice,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widget helpers ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final Widget child;
  const _Section({
    required this.title,
    required this.color,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: const Color(0xFFF1F5F9)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _NumField({required this.label, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _ToggleField extends StatelessWidget {
  final String label;
  final String fieldKey;
  final Map<String, double> cfg;
  final List<(int, String)> options;
  final void Function(String, double) onChanged;
  const _ToggleField({
    required this.label,
    required this.fieldKey,
    required this.cfg,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = cfg[fieldKey]!.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: options.map((opt) {
            final selected = current == opt.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: opt == options.last ? 0 : 4),
                child: GestureDetector(
                  onTap: () => onChanged(fieldKey, opt.$1.toDouble()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF059669) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF059669)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        opt.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
