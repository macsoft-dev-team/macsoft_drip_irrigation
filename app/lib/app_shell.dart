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
    await state.loadFields();
    if (state.token != null) {
      SocketService.instance.connect(state.token!);
      SocketService.instance.addListener(_onTelemetry);
      SocketService.instance.addMasterHeartbeatListener(_onMasterHeartbeat);
      SocketService.instance.addValveStatusListener(_onValveStatus);

      // Join rooms for all loaded fields to receive updates
      for (final field in state.fields) {
        SocketService.instance.joinField(field.id);
      }
    }
  }

  void _onTelemetry(String deviceId, TelemetryRow row) {
    context.read<AppState>().updateDeviceLive(deviceId, row);
  }

  void _onMasterHeartbeat(String mcId, Map<String, dynamic> data) {
    context.read<AppState>().updateMasterControllerLive(mcId, data);
  }

  void _onValveStatus(Map<String, dynamic> data) {
    context.read<AppState>().updateValveStatusLive(data);
  }

  Future<void> _logout() async {
    SocketService.instance.disconnect();
    await context.read<AppState>().logout();
  }

  @override
  void dispose() {
    SocketService.instance.removeListener(_onTelemetry);
    SocketService.instance.removeMasterHeartbeatListener(_onMasterHeartbeat);
    SocketService.instance.removeValveStatusListener(_onValveStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final user = state.user;
        final pages = <Widget>[
          const DashboardPage(),
          const FieldListScreen(),
        ];

        final navItems = <AppNavItem>[
          const AppNavItem(icon: Icons.home_rounded, label: 'Home'),
          const AppNavItem(icon: Icons.map_outlined, label: 'Fields'),
        ];

        if (user == null || user.canAccessSchedules) {
          pages.add(const ScheduleListScreen());
          navItems.add(const AppNavItem(icon: Icons.calendar_month_outlined, label: 'Schedules'));
        }

        if (user == null || user.canAccessStore) {
          pages.add(const StoreScreen());
          navItems.add(const AppNavItem(icon: Icons.shopping_bag_outlined, label: 'Store'));
        }

        if (user == null || user.canAccessSupport) {
          pages.add(const SupportScreen());
          navItems.add(const AppNavItem(icon: Icons.support_agent_rounded, label: 'Support'));
        }

        if (user == null || user.isAdmin) {
          pages.add(const UsersPage());
          navItems.add(const AppNavItem(icon: Icons.people_rounded, label: 'Users'));
        }

        final safeIndex = selectedIndex.clamp(0, pages.length - 1).toInt();

        return AppLayout(
          title: '',
          currentIndex: safeIndex,
          navItems: navItems,
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
