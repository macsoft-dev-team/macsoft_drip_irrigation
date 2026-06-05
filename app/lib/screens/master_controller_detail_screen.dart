import 'package:flutter/material.dart';
import '../models/master_controller.dart';
import '../widgets/status_chip.dart';
import 'support_screen.dart';

class MasterControllerDetailScreen extends StatefulWidget {
  final MasterController masterController;
  const MasterControllerDetailScreen({super.key, required this.masterController});

  @override
  State<MasterControllerDetailScreen> createState() => _MasterControllerDetailScreenState();
}

class _MasterControllerDetailScreenState extends State<MasterControllerDetailScreen> {
  bool _isRefreshing = false;
  late MasterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.masterController;
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1)); // simulated refresh
    setState(() {
      _isRefreshing = false;
      // potentially fetch updated details via API here
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device status refreshed successfully.'),
          backgroundColor: Color(0xFF2D7A3A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Controller'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.router_rounded, color: Color(0xFF2D7A3A), size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _controller.deviceUid,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E2A1F)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Status: ', style: TextStyle(fontSize: 12, color: Color(0xFF8A958A))),
                            StatusChip(status: _controller.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Specs Card
            const Text(
              'Hardware Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _SpecRow(label: 'IMEI Number', value: _controller.imei ?? 'Not Registered'),
                    _SpecRow(label: 'SIM Number', value: _controller.simNumber ?? 'No SIM Card'),
                    _SpecRow(label: 'Firmware Version', value: _controller.firmwareVersion ?? 'v1.0.0'),
                    _SpecRow(label: 'Connection Type', value: _controller.connectionType.toUpperCase()),
                    _SpecRow(label: 'IP Address', value: _controller.lastIp ?? 'N/A'),
                    _SpecRow(
                      label: 'Installed At',
                      value: _controller.installedAt != null
                          ? _controller.installedAt!.toLocal().toString().substring(0, 16)
                          : 'N/A',
                    ),
                    _SpecRow(
                      label: 'Last Heartbeat',
                      value: _controller.lastHeartbeatAt != null
                          ? _controller.lastHeartbeatAt!.toLocal().toString().substring(0, 16)
                          : 'Never',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRefreshing ? null : _refreshStatus,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D7A3A)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportTicketFormScreen(
                            initialMCId: _controller.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('Report Issue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A958A), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E2A1F), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
