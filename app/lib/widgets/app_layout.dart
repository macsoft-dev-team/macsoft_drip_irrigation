import 'package:flutter/material.dart';

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

  static const Color _primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            child: Row(
              children: [
                Image.asset('assets/logo.png', height: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A1F36),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: onLogoutTap,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(padding: const EdgeInsets.only(bottom: 86), child: child),
      floatingActionButton: FloatingActionButton(
        onPressed: onAddTap,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 72,
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black26,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _buildNavChildren(),
        ),
      ),
    );
  }

  List<Widget> _buildNavChildren() {
    final children = <Widget>[];
    final notchAfter = (navItems.length / 2).ceil() - 1;

    for (var i = 0; i < navItems.length; i++) {
      children.add(
        _NavItem(
          item: navItems[i],
          index: i,
          currentIndex: currentIndex,
          onTap: onNavTap,
        ),
      );
      if (i == notchAfter) {
        children.add(const SizedBox(width: 48));
      }
    }

    return children;
  }
}

class _NavItem extends StatelessWidget {
  final AppNavItem item;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.item,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 62,
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 23,
              color: selected ? _primary : const Color(0xFF777777),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? _primary : const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
