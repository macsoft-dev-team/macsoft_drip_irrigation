import 'package:flutter/material.dart';
import '../models/device.dart';
import '../widgets/tank_level_indicator.dart';

class DeviceDetailPage extends StatefulWidget {
  final Device device;

  const DeviceDetailPage({super.key, required this.device});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  late Device _device;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
  }

  void _togglePump() {
    setState(() {
      _device = _device.copyWith(pumpRunning: !_device.pumpRunning);
    });
    // TODO: send command to service
  }

  void _toggleMode() {
    setState(() {
      _device = _device.copyWith(
        mode: _device.mode == 'AUTO' ? 'MANUAL' : 'AUTO',
      );
    });
    // TODO: send command to service
  }

  String _formatLastSeen(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          // ── Gradient hero app bar ───────────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _device.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _device.isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _device.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('·', style: TextStyle(color: Colors.white54)),
                      const SizedBox(width: 10),
                      Text(
                        _device.mode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // ── Content ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tank level
                TankLevelIndicator(level: _device.tankLevel),
                const SizedBox(height: 16),
                // Metrics grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _MetricTile(
                      label: 'Pressure',
                      value: '${_device.pressure.toStringAsFixed(1)} bar',
                      icon: Icons.speed_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                    _MetricTile(
                      label: 'Mode',
                      value: _device.mode,
                      icon: Icons.auto_mode_rounded,
                      color: _device.mode == 'AUTO'
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFF59E0B),
                    ),
                    _MetricTile(
                      label: 'Pump',
                      value: _device.pumpRunning ? 'Running' : 'Stopped',
                      icon: Icons.electric_bolt_rounded,
                      color: _device.pumpRunning
                          ? const Color(0xFF10B981)
                          : const Color(0xFF9CA3AF),
                    ),
                    _MetricTile(
                      label: 'Last Seen',
                      value: _formatLastSeen(_device.lastSeen),
                      icon: Icons.access_time_rounded,
                      color: const Color(0xFF6B7280),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Controls
                const Text(
                  'Controls',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ControlButton(
                        label: _device.pumpRunning ? 'Stop Pump' : 'Start Pump',
                        icon: _device.pumpRunning
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_rounded,
                        color: _device.pumpRunning
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        onPressed: _device.isOnline ? _togglePump : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ControlButton(
                        label: _device.mode == 'AUTO' ? 'Go Manual' : 'Go Auto',
                        icon: _device.mode == 'AUTO'
                            ? Icons.tune_rounded
                            : Icons.auto_mode_rounded,
                        color: const Color(0xFF1565C0),
                        onPressed: _device.isOnline ? _toggleMode : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? color : const Color(0xFFE5E7EB),
        foregroundColor: active ? Colors.white : const Color(0xFF9CA3AF),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
