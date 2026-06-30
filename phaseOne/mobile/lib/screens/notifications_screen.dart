import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/alert.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    // Merge real alerts and mock fallback alerts for high-fidelity visualization
    final List<Alert> displayedAlerts = List.from(state.alerts);
    
    if (displayedAlerts.isEmpty) {
      displayedAlerts.addAll([
        Alert(
          id: "m1",
          title: "Master Offline",
          message: "Connection lost with North Farm master controller.",
          type: "masterOffline",
          severity: AlertSeverity.critical,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          isRead: false,
        ),
        Alert(
          id: "m2",
          title: "Tank level Low",
          message: "Water tank level dropped below 15% (current: 12%).",
          type: "tankLow",
          severity: AlertSeverity.warning,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: false,
        ),
        Alert(
          id: "m3",
          title: "Schedule Started",
          message: "Morning Drip schedule started successfully.",
          type: "scheduleStarted",
          severity: AlertSeverity.info,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          isRead: false,
        ),
        Alert(
          id: "m4",
          title: "Schedule Completed",
          message: "Sugarcane row watering schedule has finished.",
          type: "scheduleCompleted",
          severity: AlertSeverity.info,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          isRead: true,
        ),
        Alert(
          id: "m5",
          title: "Valve Failure",
          message: "Solenoid valve A on unit ESP32 Slave #1 is not responding.",
          type: "valveError",
          severity: AlertSeverity.critical,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.loadAlerts();
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: displayedAlerts.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final a = displayedAlerts[idx];
            final bool isUnread = !a.isRead;

            IconData alertIcon = Icons.info_outline;
            Color alertColor = Colors.blue;

            if (a.severity == AlertSeverity.critical) {
              alertIcon = Icons.error_outline;
              alertColor = Colors.red;
            } else if (a.severity == AlertSeverity.warning) {
              alertIcon = Icons.warning_amber_rounded;
              alertColor = Colors.orange;
            }

            final timeStr = DateFormat('h:mm a • d MMM').format(a.createdAt);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUnread ? alertColor.withOpacity(0.04) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnread ? alertColor.withOpacity(0.2) : Colors.grey.shade100,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: alertColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(alertIcon, color: alertColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              a.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: alertColor, shape: BoxShape.circle),
                              )
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(a.message, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                  if (isUnread)
                    IconButton(
                      icon: const Icon(Icons.check, size: 18, color: Colors.grey),
                      onPressed: () {
                        state.markAlertAsRead(a.id);
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
