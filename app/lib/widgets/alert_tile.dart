import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertTile extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const AlertTile({super.key, required this.alert, this.onTap});

  Color get _color {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return const Color(0xFFEF4444);
      case AlertSeverity.warning:
        return const Color(0xFFF59E0B);
      case AlertSeverity.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get _icon {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Icons.error_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: alert.isRead
            ? null
            : BoxDecoration(color: color.withOpacity(0.04)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: alert.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: const Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${alert.deviceName} · ${_formatTime(alert.timestamp)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (!alert.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
