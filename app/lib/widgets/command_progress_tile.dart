import 'package:flutter/material.dart';
import '../models/command.dart';
import 'status_chip.dart';

class CommandProgressTile extends StatelessWidget {
  final CommandItem item;

  const CommandProgressTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Widget leadingWidget;

    switch (item.status.toLowerCase()) {
      case 'acknowledged':
        iconColor = const Color(0xFF2D7A3A);
        leadingWidget = Icon(Icons.check_circle, color: iconColor, size: 22);
        break;
      case 'sent':
        iconColor = const Color(0xFFEF6C00);
        leadingWidget = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF6C00)),
          ),
        );
        break;
      case 'failed':
      case 'timeout':
        iconColor = const Color(0xFFC62828);
        leadingWidget = Icon(Icons.cancel, color: iconColor, size: 22);
        break;
      case 'pending':
      default:
        iconColor = const Color(0xFF9E9E9E);
        leadingWidget = Icon(Icons.radio_button_unchecked, color: iconColor, size: 22);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Row(
        children: [
          leadingWidget,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.valveName ?? 'Valve #${item.valveId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E2A1F),
                  ),
                ),
                Text(
                  'Action: ${item.action.toUpperCase()} • Seq #${item.sequenceNumber}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8A958A)),
                ),
                if (item.failedReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.failedReason!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFC62828)),
                    ),
                  ),
              ],
            ),
          ),
          StatusChip(status: item.status),
        ],
      ),
    );
  }
}
