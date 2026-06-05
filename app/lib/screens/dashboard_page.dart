import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/alert_tile.dart';
import '../widgets/status_chip.dart';
import 'field_list_screen.dart';
import 'schedule_list_screen.dart';
import 'store_screen.dart';
import 'support_screen.dart';
import 'profile_screen.dart';

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
                  // Greeting & Profile Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Namaste, ${state.user?.name ?? "Farmer"}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E2A1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'Here is your irrigation status today.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF8A958A)),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE8F5E9),
                          child: Text(
                            (state.user?.name?.isNotEmpty == true ? state.user!.name![0] : 'U').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF2D7A3A),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
