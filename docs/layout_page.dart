import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// MAIN APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FarmerHomePage(),
    );
  }
}

// SAMPLE PAGE
class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  State<FarmerHomePage> createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: currentIndex,
      onNavTap: (index) {
        setState(() {
          currentIndex = index;
        });
      },
      onAddTap: () {},
      child: Center(
        child: Text(
          _getPageTitle(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (currentIndex) {
      case 0:
        return "Home Page";
      case 1:
        return "Crops Page";
      case 2:
        return "Market Page";
      case 3:
        return "Profile Page";
      default:
        return "Home Page";
    }
  }
}

// REUSABLE LAYOUT
class AppLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int index) onNavTap;
  final VoidCallback onAddTap;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavTap,
    required this.onAddTap,
  });

  static const Color green = Color(0xFF35B84B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      extendBody: true,

      // TOP APP BAR ONLY
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            color: const Color(0xFFF7F8FA),
            child: Row(
              children: [
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(
                    Icons.menu_rounded,
                    size: 26,
                    color: Colors.black,
                  ),
                ),

                const Spacer(),

                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 26,
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFFFD59A),
                  child: Icon(Icons.person, color: Colors.brown, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),

      body: Padding(padding: const EdgeInsets.only(bottom: 85), child: child),

      floatingActionButton: FloatingActionButton(
        onPressed: onAddTap,
        backgroundColor: green,
        elevation: 5,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 12,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.home_rounded,
                label: "Home",
                onTap: onNavTap,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.eco_outlined,
                label: "Crops",
                onTap: onNavTap,
              ),

              const SizedBox(width: 52),

              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.bar_chart_rounded,
                label: "Market",
                onTap: onNavTap,
              ),
              _NavItem(
                index: 3,
                currentIndex: currentIndex,
                icon: Icons.person_outline_rounded,
                label: "Profile",
                onTap: onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// BOTTOM NAV ITEM
class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final Function(int index) onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const Color green = Color(0xFF35B84B);

  @override
  Widget build(BuildContext context) {
    final bool selected = index == currentIndex;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 58,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? green : const Color(0xFF777777),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected ? green : const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
