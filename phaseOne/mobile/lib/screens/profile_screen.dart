import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = state.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bio Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2D7A3A), width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 46,
                    backgroundColor: Color(0xFF2D7A3A),
                    child: Icon(Icons.person, size: 54, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? "Farmer User",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.phone ?? "No phone number",
                  style: const TextStyle(color: Colors.black54),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D7A3A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Role: ${(user?.role?.toString() ?? 'FARMER').toUpperCase()}",
                    style: const TextStyle(color: Color(0xFF2D7A3A), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Farm Info Card
          const Text("Farm Information", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A))),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileRow("Village Location", "Rampur, Punjab"),
                  _buildProfileRow("Drip System Installed", "September 2025"),
                  _buildProfileRow("Associated fields count", "${state.fields.length}"),
                  _buildProfileRow("Admin Support", "Admin Helpdesk (+91 1800 555 9999)"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Settings Card
          const Text("Application Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A))),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Offline Notifications Cache", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    value: true,
                    activeColor: const Color(0xFF2D7A3A),
                    onChanged: (v) {},
                  ),
                  SwitchListTile(
                    title: const Text("AI Telemetry Optimization", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    value: true,
                    activeColor: const Color(0xFF2D7A3A),
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Password reset card
          const Text("Security Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A))),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _oldPassController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Current Password"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newPassController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "New Password"),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {
                      if (_oldPassController.text.isNotEmpty && _newPassController.text.isNotEmpty) {
                        _oldPassController.clear();
                        _newPassController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password updated successfully!")),
                        );
                      }
                    },
                    child: const Text("UPDATE PASSWORD"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await state.logout();
            },
            child: const Text("LOG OUT"),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
