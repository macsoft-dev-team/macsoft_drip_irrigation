import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/master_controller.dart';
import '../models/api_device.dart';
import '../services/app_state.dart';
import '../widgets/status_chip.dart';
import '../widgets/tank_level_indicator.dart';
import '../widgets/confirm_action_dialog.dart';
import 'support_screen.dart';
import 'device_config_page.dart';

class MasterControllerDetailScreen extends StatefulWidget {
  final MasterController masterController;
  const MasterControllerDetailScreen({super.key, required this.masterController});

  @override
  State<MasterControllerDetailScreen> createState() => _MasterControllerDetailScreenState();
}

class _MasterControllerDetailScreenState extends State<MasterControllerDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadDevices();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    final state = context.read<AppState>();
    await state.loadFields();
    setState(() => _isRefreshing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device status refreshed successfully.'),
          backgroundColor: Color(0xFF2D7A3A),
        ),
      );
    }
  }

  Future<void> _togglePump(MasterController controller, bool start) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: start ? 'Start Pump Motor' : 'Stop Pump Motor',
      content: start
          ? 'Are you sure you want to turn ON the water pump motor?'
          : 'Are you sure you want to turn OFF the water pump motor?',
      isDestructive: !start,
    );

    if (confirmed && mounted) {
      final state = context.read<AppState>();
      final ok = await state.controlMotor(controller.id, start ? 'start' : 'stop');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Pump motor command dispatched successfully.'
                : 'Failed to dispatch command to pump motor.'),
            backgroundColor: ok ? const Color(0xFF2D7A3A) : const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final fieldIdx = state.fields.indexWhere((f) => f.masterController?.id == widget.masterController.id);
        final liveController = fieldIdx != -1 ? state.fields[fieldIdx].masterController : widget.masterController;
        final controller = liveController ?? widget.masterController;

        final isPumpRunning = controller.motorStatus == 'on';
        final isOnline = controller.isOnline;
        final isAdmin = state.user?.isAdmin ?? false;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: AppBar(
            title: const Text('Master Controller'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.router_rounded, color: Color(0xFF2D7A3A), size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.deviceUid,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E2A1F)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Status: ', style: TextStyle(fontSize: 12, color: Color(0xFF8A958A))),
                                StatusChip(status: controller.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tank Level Indicator
                TankLevelIndicator(level: (controller.tankLevel ?? 50).toDouble()),
                const SizedBox(height: 20),

                // Water Pump Motor Control Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                    border: Border.all(
                      color: isPumpRunning ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Water Pump Motor',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E2A1F),
                                ),
                              ),
                            ],
                          ),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPumpRunning
                                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                      : const Color(0xFF9CA3AF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPumpRunning)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF10B981).withValues(alpha: _pulseController.value),
                                        ),
                                      ),
                                    Text(
                                      isPumpRunning ? 'RUNNING' : 'STOPPED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: isPumpRunning ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Control the main field water pump manually. Ensure the master controller is online to receive commands.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8A958A), height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isOnline ? () => _togglePump(controller, !isPumpRunning) : null,
                          icon: Icon(
                            isPumpRunning ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
                            size: 20,
                          ),
                          label: Text(
                            isPumpRunning ? 'Stop Pump Motor' : 'Start Pump Motor',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPumpRunning ? const Color(0xFFEF4444) : const Color(0xFF2D7A3A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (!isOnline) ...[
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Pump commands disabled: Master Controller is offline',
                            style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Specs Card
                const Text(
                  'Hardware Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _SpecRow(label: 'IMEI Number', value: controller.imei ?? 'Not Registered'),
                        _SpecRow(label: 'SIM Number', value: controller.simNumber ?? 'No SIM Card'),
                        _SpecRow(label: 'Firmware Version', value: controller.firmwareVersion ?? 'v1.0.0'),
                        _SpecRow(label: 'Connection Type', value: controller.connectionType.toUpperCase()),
                        _SpecRow(label: 'IP Address', value: controller.lastIp ?? 'N/A'),
                        _SpecRow(
                          label: 'Installed At',
                          value: controller.installedAt != null
                              ? controller.installedAt!.toLocal().toString().substring(0, 16)
                              : 'N/A',
                        ),
                        _SpecRow(
                          label: 'Last Heartbeat',
                          value: controller.lastHeartbeatAt != null
                              ? controller.lastHeartbeatAt!.toLocal().toString().substring(0, 16)
                              : 'Never',
                        ),
                      ],
                    ),
                  ),
                ),

                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final apiDevice = state.devices.firstWhere(
                          (d) => d.imeinumber == controller.imei || d.imeinumber == controller.deviceUid,
                          orElse: () => ApiDevice(
                            id: controller.id,
                            imeinumber: controller.imei ?? controller.deviceUid,
                            name: controller.deviceUid,
                            isActive: controller.isOnline,
                            config: const {},
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceConfigPage(device: apiDevice),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_suggest_rounded),
                      label: const Text('Configure Device Parameters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2A1F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRefreshing ? null : _refreshStatus,
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D7A3A)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SupportTicketFormScreen(
                                initialMCId: controller.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bug_report_outlined),
                        label: const Text('Report Issue'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A958A), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E2A1F), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
