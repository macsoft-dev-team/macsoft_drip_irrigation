import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/socket_service.dart';
import 'screens/home_screen.dart';
import 'screens/irrigation_screen.dart';
import 'screens/schedules_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/support_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const IrrigationScreen(),
    const SchedulesScreen(),
    const AiAssistantScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSockets());
  }

  void _initSockets() {
    final state = context.read<AppState>();
    if (state.token != null) {
      SocketService.instance.connect(state.token!);
      for (final field in state.fields) {
        SocketService.instance.joinField(field.id);
      }
    }
  }

  @override
  void dispose() {
    SocketService.instance.disconnect();
    super.dispose();
  }

  Widget _buildBottomNav(AppState state) {
    final activeColor = const Color(0xFF2D7A3A);
    final inactiveColor = Colors.grey.shade400;

    final icons = [
      (Icons.home_outlined, Icons.home, "Home"),
      (Icons.water_drop_outlined, Icons.water_drop, "Irrigation"),
      (Icons.calendar_today_outlined, Icons.calendar_today, "Schedule"),
      (Icons.smart_toy_outlined, Icons.smart_toy, "AI"),
      (Icons.person_outline, Icons.person, "Profile"),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(icons.length, (idx) {
              final isSelected = state.currentTab == idx;
              final config = icons[idx];
              final icon = isSelected ? config.$2 : config.$1;
              final label = config.$3;

              return GestureDetector(
                onTap: () {
                  state.setTab(idx);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 22),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: activeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      extendBody: false,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.opacity, color: Color(0xFF2D7A3A)),
            SizedBox(width: 8),
            Text("MACSOFT DRIP"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SupportScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: state.currentTab,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(state),
    );
  }
}

