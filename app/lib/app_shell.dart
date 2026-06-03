import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/api_device.dart';
import 'models/app_user.dart';
import 'services/app_state.dart';
import 'services/socket_service.dart';
import 'widgets/app_layout.dart';
import 'widgets/import_devices_sheet.dart';
import 'screens/alerts_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/device_list_page.dart';
import 'screens/users_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
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

  Future<void> _logout() async {
    SocketService.instance.disconnect();
    await context.read<AppState>().logout();
  }

  @override
  void dispose() {
    SocketService.instance.removeListener(_onTelemetry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final isAdmin =
            state.user?.role == UserRole.admin ||
            state.user?.role == UserRole.superadmin;

        // DripFlow nav: Dashboard | Systems | Valves | Schedules | More
        final pages = [
          const DashboardPage(),
          const DeviceListPage(),
          isAdmin ? const UsersPage() : const AlertsPage(alerts: []),
          const _SchedulesPage(),
          _MorePage(onLogout: _logout, user: state.user),
        ];

        final safeIndex = selectedIndex.clamp(0, pages.length - 1).toInt();

        return AppLayout(
          title: '',
          currentIndex: safeIndex,
          navItems: const [
            AppNavItem(icon: Icons.home_rounded, label: 'Dashboard'),
            AppNavItem(icon: Icons.settings_outlined, label: 'Systems'),
            AppNavItem(icon: Icons.groups_outlined, label: 'Users'),
            AppNavItem(icon: Icons.calendar_month_outlined, label: 'Schedules'),
            AppNavItem(icon: Icons.menu_rounded, label: 'More'),
          ],
          onNavTap: (i) => setState(() => selectedIndex = i),
          onAddTap: () {
            if (safeIndex == 1 && isAdmin) {
              ImportDevicesSheet.show(
                context,
                token: state.token ?? '',
                onSuccess: state.loadDevices,
              );
            }
          },
          onLogoutTap: _logout,
          child: pages[safeIndex],
        );
      },
    );
  }
}

// ── Schedules placeholder ─────────────────────────────────────────────────────

class _SchedulesPage extends StatelessWidget {
  const _SchedulesPage();

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonPage(
      icon: Icons.calendar_month_outlined,
      title: 'Schedules',
      subtitle: 'Irrigation schedules coming soon.',
    );
  }
}

// ── More / profile page ───────────────────────────────────────────────────────

class _MorePage extends StatelessWidget {
  final VoidCallback onLogout;
  final AppUser? user;
  const _MorePage({required this.onLogout, this.user});

  static const _primary = Color(0xFF2D7A3A);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Text(
                  (user?.name?.isNotEmpty == true
                          ? user!.name![0]
                          : user?.email?.isNotEmpty == true
                          ? user!.email![0]
                          : 'U')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? user?.email ?? 'User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2A1F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.roleLabel ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A958A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _MoreTile(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () {},
        ),
        _MoreTile(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () {},
        ),
        _MoreTile(
          icon: Icons.info_outline_rounded,
          label: 'About DripFlow',
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _MoreTile(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          color: const Color(0xFFDC2626),
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF1E2A1F),
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFCBD5E1),
      ),
      onTap: onTap,
    );
  }
}

// ── Coming soon placeholder ───────────────────────────────────────────────────

class _ComingSoonPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ComingSoonPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}
