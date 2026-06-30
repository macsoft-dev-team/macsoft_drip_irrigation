import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../screens/profile_screen.dart';

class AppNavItem {
  final IconData icon;
  final String label;

  const AppNavItem({required this.icon, required this.label});
}

class AppLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final int currentIndex;
  final List<AppNavItem> navItems;
  final ValueChanged<int> onNavTap;
  final VoidCallback onAddTap;
  final VoidCallback onLogoutTap;

  const AppLayout({
    super.key,
    required this.title,
    required this.child,
    required this.currentIndex,
    required this.navItems,
    required this.onNavTap,
    required this.onAddTap,
    required this.onLogoutTap,
  });

  static const Color _primary = Color(0xFF2D7A3A);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      extendBody: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            color: Colors.white,
            child: Row(
              children: [
                
                const SizedBox(width: 12),
                // Logo + brand
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DripFlow',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E2A1F),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Smart Irrigation',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8A958A),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Notification bell with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 26,
                      color: Color(0xFF1E2A1F),
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFE2F3D5),
                      child: Text(
                        (user?.name?.isNotEmpty == true ? user!.name![0] : '🌿').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D7A3A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(navItems.length, (i) {
                final item = navItems[i];
                final selected = i == currentIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => onNavTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: selected ? _primary : const Color(0xFF9BA89B),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? _primary
                                : const Color(0xFF9BA89B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (selected)
                          Container(
                            width: 18,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        else
                          const SizedBox(height: 3),
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
}
