import 'package:flutter/material.dart';
import '../models/field.dart';
import 'status_chip.dart';

class FieldCard extends StatelessWidget {
  final Field field;
  final VoidCallback onTap;

  const FieldCard({
    super.key,
    required this.field,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final int totalZones = field.zones.length;
    int totalValves = 0;
    int openValves = 0;

    for (var zone in field.zones) {
      totalValves += zone.valves.length;
      openValves += zone.valves.where((v) => v.status == 'open').length;
    }

    final String masterStatus = field.masterController?.status ?? 'offline';
    final String lastHeartbeat = field.masterController?.lastHeartbeatAt != null
        ? _formatTimeAgo(field.masterController!.lastHeartbeatAt!)
        : 'Never';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      field.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2A1F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(status: masterStatus),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF8A958A)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      field.locationName ?? 'No location details',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A958A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.8, color: Color(0xFFE8F5E9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Metric(label: 'Zones', value: '$totalZones'),
                  _Metric(label: 'Total Valves', value: '$totalValves'),
                  _Metric(
                    label: 'Open Valves',
                    value: '$openValves',
                    valueColor: openValves > 0 ? const Color(0xFF2D7A3A) : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt, size: 14, color: Color(0xFF8A958A)),
                      const SizedBox(width: 2),
                      Text(
                        'Master: ${field.masterController?.deviceUid ?? "N/A"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8A958A)),
                      ),
                    ],
                  ),
                  Text(
                    'Heartbeat: $lastHeartbeat',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF8A958A)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Metric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8A958A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF1E2A1F),
          ),
        ),
      ],
    );
  }
}
