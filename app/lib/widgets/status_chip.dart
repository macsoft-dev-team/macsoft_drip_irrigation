import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'online':
      case 'open':
      case 'active':
      case 'acknowledged':
      case 'paid':
      case 'delivered':
      case 'resolved':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2D7A3A);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'offline':
      case 'closed':
      case 'inactive':
      case 'queued':
      case 'sent':
      case 'created':
      case 'pending':
      case 'confirmed':
        bgColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF546E7A);
        icon = Icons.radio_button_unchecked_rounded;
        break;
      case 'dispatched':
      case 'inprogress':
      case 'partialsuccess':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFEF6C00);
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'error':
      case 'failed':
      case 'critical':
      case 'timeout':
      case 'expired':
      case 'cancelled':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        icon = Icons.error_outline_rounded;
        break;
      case 'disabled':
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF9E9E9E);
        icon = Icons.block_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
