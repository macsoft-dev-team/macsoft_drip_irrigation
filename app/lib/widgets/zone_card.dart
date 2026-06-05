import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../models/valve.dart';
import 'valve_tile.dart';

class ZoneCard extends StatelessWidget {
  final Zone zone;
  final bool isMasterOnline;
  final Function(Valve) onValveOpen;
  final Function(Valve) onValveClose;
  final Function(Valve) onValveTap;
  final VoidCallback onOpenZone;
  final VoidCallback onCloseZone;
  final VoidCallback onAddValve;
  final VoidCallback onCreateSchedule;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.isMasterOnline,
    required this.onValveOpen,
    required this.onValveClose,
    required this.onValveTap,
    required this.onOpenZone,
    required this.onCloseZone,
    required this.onAddValve,
    required this.onCreateSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final int openCount = zone.valves.where((v) => v.status == 'open').length;
    final int totalCount = zone.valves.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A1F),
                        ),
                      ),
                      if (zone.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          zone.description!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A)),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: openCount > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$openCount / $totalCount Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: openCount > 0 ? const Color(0xFF2D7A3A) : const Color(0xFF546E7A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenZone,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Open Zone'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D7A3A),
                      side: const BorderSide(color: Color(0xFF2D7A3A)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCloseZone,
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Close Zone'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: onAddValve,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Valve', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D7A3A)),
                ),
                TextButton.icon(
                  onPressed: onCreateSchedule,
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: const Text('Schedule', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D7A3A)),
                ),
              ],
            ),
            if (zone.valves.isNotEmpty) ...[
              const Divider(height: 20, thickness: 0.8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: zone.valves.length,
                itemBuilder: (context, i) {
                  final valve = zone.valves[i];
                  return ValveTile(
                    valve: valve,
                    isMasterOnline: isMasterOnline,
                    onOpen: () => onValveOpen(valve),
                    onClose: () => onValveClose(valve),
                    onTap: () => onValveTap(valve),
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No valves added to this zone yet.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A958A), fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
