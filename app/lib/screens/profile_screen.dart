import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/confirm_action_dialog.dart';
import 'support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    (user?.name?.isNotEmpty == true ? user!.name![0] : 'U').toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2D7A3A),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User Name',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.phone ?? 'No Phone Number',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8A958A)),
                      ),
                      Text(
                        'Role: ${user?.roleLabel ?? "Farmer"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8A958A), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details Section
          const Text('Farm Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E2A1F))),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _InfoRow(label: 'Village', value: 'Gate No. 3 Village'),
                  _InfoRow(label: 'District', value: 'Ahmednagar'),
                  _InfoRow(label: 'State', value: 'Maharashtra'),
                  _InfoRow(label: 'Pincode', value: '414001'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Settings Section
          const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E2A1F))),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Color(0xFF2D7A3A)),
                  title: const Text('Language Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Text('English (EN)', style: TextStyle(fontSize: 12, color: Color(0xFF8A958A))),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language settings popup placeholder.')),
                    );
                  },
                ),
                const Divider(height: 1, thickness: 0.8),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2D7A3A)),
                  title: const Text('SMS / Mobile Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  value: _notificationsEnabled,
                  activeColor: const Color(0xFF2D7A3A),
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                  },
                ),
                const Divider(height: 1, thickness: 0.8),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Color(0xFF2D7A3A)),
                  title: const Text('Help Desk & FAQ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
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
          const SizedBox(height: 32),

          // Logout button
          ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await ConfirmActionDialog.show(
                context,
                title: 'Sign Out',
                content: 'Are you sure you want to log out of your farmer account?',
                confirmLabel: 'Sign Out',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                Navigator.pop(context); // pop back first
                await context.read<AppState>().logout();
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.white),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A958A))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F))),
        ],
      ),
    );
  }
}
