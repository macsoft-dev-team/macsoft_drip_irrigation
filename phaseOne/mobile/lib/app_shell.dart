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

  Widget _buildBottomNav() {
    final activeColor = const Color(0xFF1E4D2B);
    final inactiveColor = Colors.grey.shade400;

    final icons = [
      (Icons.home_outlined, Icons.home, "Home"),
      (Icons.water_drop_outlined, Icons.water_drop, "Irrigation"),
      (Icons.calendar_today_outlined, Icons.calendar_today, "Schedule"),
      (Icons.smart_toy_outlined, Icons.smart_toy, "AI"),
      (Icons.person_outline, Icons.person, "Profile"),
    ];

    return Container(
      height: 66,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            color: Colors.white.withOpacity(0.90),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(icons.length, (idx) {
                final isSelected = _currentIndex == idx;
                final config = icons[idx];
                final icon = isSelected ? config.$2 : config.$1;
                final label = config.$3;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = idx;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
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
                              fontSize: 11.5,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.opacity, color: Color(0xFF1E4D2B)),
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
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

