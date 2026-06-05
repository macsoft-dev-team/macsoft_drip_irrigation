import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/api_device.dart';
import 'services/app_state.dart';
import 'services/socket_service.dart';
import 'widgets/app_layout.dart';
import 'screens/dashboard_page.dart';
import 'screens/field_list_screen.dart';
import 'screens/schedule_list_screen.dart';
import 'screens/store_screen.dart';
import 'screens/support_screen.dart';

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
    await state.loadFields();
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
        final pages = [
          const DashboardPage(),
          const FieldListScreen(),
          const ScheduleListScreen(),
          const StoreScreen(),
          const SupportScreen(),
        ];

        final safeIndex = selectedIndex.clamp(0, pages.length - 1).toInt();

        return AppLayout(
          title: '',
          currentIndex: safeIndex,
          navItems: const [
            AppNavItem(icon: Icons.home_rounded, label: 'Home'),
            AppNavItem(icon: Icons.map_outlined, label: 'Fields'),
            AppNavItem(icon: Icons.calendar_month_outlined, label: 'Schedules'),
            AppNavItem(icon: Icons.shopping_bag_outlined, label: 'Store'),
            AppNavItem(icon: Icons.support_agent_rounded, label: 'Support'),
          ],
          onNavTap: (i) => setState(() => selectedIndex = i),
          onAddTap: () {
            // Action handled locally if needed, e.g. open side menu or details
          },
          onLogoutTap: _logout,
          child: pages[safeIndex],
        );
      },
    );
  }
}
