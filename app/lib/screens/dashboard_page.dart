import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/app_state.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/alert_tile.dart';
import '../widgets/status_chip.dart';
import 'field_list_screen.dart';
import 'schedule_list_screen.dart';
import 'store_screen.dart';
import 'support_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadFields();
      state.loadSchedules();
      state.loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: RefreshIndicator(
        onRefresh: () async {
          final state = context.read<AppState>();
          await state.loadFields();
          await state.loadSchedules();
          await state.loadAlerts();
        },
        child: Consumer<AppState>(
          builder: (context, state, _) {
            // Calculations for metrics
            final int totalFields = state.fields.length;
            final int onlineMasters = state.fields.where((f) => f.masterController?.isOnline ?? false).length;

            int openValves = 0;
            for (var f in state.fields) {
              for (var z in f.zones) {
                openValves += z.valves.where((v) => v.status == 'open').length;
              }
            }

            final int activeAlerts = state.alerts.where((a) => !a.isRead).length;
            final int todaySchedules = state.schedules.where((s) => s.status == 'active').length;
            final int failedCommands = state.alerts.where((a) => a.type == 'commandFailed').length;

            final unreadAlerts = state.alerts.where((a) => !a.isRead).take(3).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weather / Farm scene card
                  _weatherCard(),
                  const SizedBox(height: 20),

                  // Metrics Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                    children: [
                      DashboardMetricCard(
                        title: 'Total Fields',
                        value: '$totalFields',
                        icon: Icons.grid_on_rounded,
                        color: const Color(0xFF2D7A3A),
                        onTap: () {
                          // Navigate to Fields page in AppShell (which is at index 1)
                          // We can handle this by modifying AppShell index but for now push FieldListScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FieldListScreen()),
                          );
                        },
                      ),
                      DashboardMetricCard(
                        title: 'Online Masters',
                        value: '$onlineMasters/$totalFields',
                        icon: Icons.wifi,
                        color: const Color(0xFF3B82F6),
                      ),
                      DashboardMetricCard(
                        title: 'Open Valves',
                        value: '$openValves',
                        icon: Icons.water_drop,
                        color: const Color(0xFF10B981),
                      ),
                      DashboardMetricCard(
                        title: 'Failed Commands',
                        value: '$failedCommands',
                        icon: Icons.cancel_schedule_send_rounded,
                        color: const Color(0xFFEF4444),
                      ),
                      DashboardMetricCard(
                        title: 'Active Schedules',
                        value: '$todaySchedules',
                        icon: Icons.calendar_month,
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ScheduleListScreen()),
                          );
                        },
                      ),
                      DashboardMetricCard(
                        title: 'Unread Alerts',
                        value: '$activeAlerts',
                        icon: Icons.notifications_active,
                        color: const Color(0xFFEC4899),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Quick Actions Row
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 104,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _QuickActionBtn(
                          icon: Icons.add_location_alt_rounded,
                          label: 'Add Field',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FieldFormScreen(),
                              ),
                            );
                          },
                        ),
                        _QuickActionBtn(
                          icon: Icons.map_rounded,
                          label: 'View Fields',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FieldListScreen()),
                            );
                          },
                        ),
                        _QuickActionBtn(
                          icon: Icons.add_alarm_rounded,
                          label: 'Add Schedule',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ScheduleFormScreen(),
                              ),
                            );
                          },
                        ),
                        _QuickActionBtn(
                          icon: Icons.shopping_bag_rounded,
                          label: 'Shop Products',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StoreScreen()),
                            );
                          },
                        ),
                        _QuickActionBtn(
                          icon: Icons.support_agent_rounded,
                          label: 'Support',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SupportScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Active / Recent Command tracker
                  if (state.activeCommand != null) ...[
                    const Text(
                      'Live Commands',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Command UID: ${state.activeCommand!.commandUid}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              StatusChip(status: state.activeCommand!.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Action: ${state.activeCommand!.action.toUpperCase()} ${state.activeCommand!.targetType.toUpperCase()} #${state.activeCommand!.targetId}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF546E7A)),
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(
                            height: 2,
                            child: LinearProgressIndicator(
                              backgroundColor: Color(0xFFECEFF1),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A3A)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Device status is updating live...',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF8A958A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Recent Alerts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Alerts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                      ),
                      if (unreadAlerts.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // Navigate to alerts tab
                          },
                          child: const Text('View All', style: TextStyle(color: Color(0xFF2D7A3A))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (unreadAlerts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'All clear! No new alerts.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF8A958A)),
                      ),
                    )
                  else
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: unreadAlerts.length,
                        separatorBuilder: (context, i) => const Divider(height: 1, thickness: 0.8, color: Color(0xFFECEFF1)),
                        itemBuilder: (context, i) {
                          final alert = unreadAlerts[i];
                          return AlertTile(
                            alert: alert,
                            onTap: () {
                              state.markAlertAsRead(alert.id);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static const _darkText = Color(0xFF1E2A1F);
  static const _greyText = Color(0xFF8A958A);

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
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF2D7A3A), size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2A1F),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
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

