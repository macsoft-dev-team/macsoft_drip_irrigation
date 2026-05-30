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

        final titles = [
          'Overview',
          'Devices',
          if (isAdmin) 'Users' else 'Alerts',
          'Profile',
        ];

        final pages = [
          const DashboardPage(),
          const DeviceListPage(),
          if (isAdmin) const UsersPage() else const AlertsPage(alerts: []),
          const _ProfilePage(),
        ];

        final safeIndex = selectedIndex.clamp(0, pages.length - 1).toInt();

        return AppLayout(
          title: titles[safeIndex],
          currentIndex: safeIndex,
          navItems: [
            const AppNavItem(icon: Icons.home_rounded, label: 'Home'),
            const AppNavItem(icon: Icons.devices_outlined, label: 'Devices'),
            AppNavItem(
              icon: isAdmin
                  ? Icons.people_outline_rounded
                  : Icons.notifications_none_rounded,
              label: isAdmin ? 'Users' : 'Alerts',
            ),
            const AppNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
            ),
          ],
          onNavTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          onAddTap: () {
            if (safeIndex == 1 && isAdmin) {
              ImportDevicesSheet.show(
                context,
                token: state.token ?? '',
                onSuccess: state.loadDevices,
              );
            } else {
              setState(() {
                selectedIndex = 1;
              });
            }
          },
          onLogoutTap: _logout,
          child: pages[safeIndex],
        );
      },
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Text(
                (user?.name?.isNotEmpty == true
                        ? user!.name![0]
                        : user?.email?.isNotEmpty == true
                        ? user!.email![0]
                        : 'U')
                    .toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.name ?? user?.email ?? 'User',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.roleLabel ?? '',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
