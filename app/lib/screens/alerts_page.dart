import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../widgets/alert_tile.dart';

class AlertsPage extends StatefulWidget {
  final List<Alert> alerts;

  const AlertsPage({super.key, required this.alerts});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late List<Alert> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = List.from(widget.alerts);
  }

  void _markAllRead() {
    setState(() {
      _alerts = _alerts
          .map(
            (a) => Alert(
              id: a.id,
              deviceId: a.deviceId,
              deviceName: a.deviceName,
              message: a.message,
              severity: a.severity,
              timestamp: a.timestamp,
              isRead: true,
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _alerts.where((a) => !a.isRead).length;

    if (_alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('No alerts', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (unread > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$unread unread',
                  style: const TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: _markAllRead,
                  child: const Text('Mark all as read'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: _alerts.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              return AlertTile(
                alert: alert,
                onTap: () {
                  setState(() {
                    _alerts[index] = Alert(
                      id: alert.id,
                      deviceId: alert.deviceId,
                      deviceName: alert.deviceName,
                      message: alert.message,
                      severity: alert.severity,
                      timestamp: alert.timestamp,
                      isRead: true,
                    );
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
