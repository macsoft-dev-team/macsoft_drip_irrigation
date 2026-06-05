import 'package:flutter/material.dart';
import '../models/valve.dart';
import 'status_chip.dart';

class ValveTile extends StatelessWidget {
  final Valve valve;
  final bool isMasterOnline;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const ValveTile({
    super.key,
    required this.valve,
    required this.isMasterOnline,
    required this.onOpen,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOpen = valve.status == 'open';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                valve.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E2A1F),
                ),
              ),
            ),
            StatusChip(status: valve.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valve #${valve.valveNumber} • ${valve.deviceUid}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A)),
              ),
              if (valve.lastStatusAt != null)
                Text(
                  _formatTime(valve.lastStatusAt!),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8A958A)),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMasterOnline)
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                tooltip: 'Master controller is offline. Command will be queued.',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Master controller is offline. Command will be queued for limited time.'),
                      backgroundColor: Colors.amber,
                    ),
                  );
                },
              ),
            FilledButton.tonal(
              onPressed: isOpen ? onClose : onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: isOpen
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                foregroundColor: isOpen
                    ? const Color(0xFFC62828)
                    : const Color(0xFF2D7A3A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(80, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isOpen ? 'CLOSE' : 'OPEN',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}
