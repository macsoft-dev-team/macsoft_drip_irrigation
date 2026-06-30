import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/field.dart';
import '../models/zone.dart';
import '../widgets/tank_level_indicator.dart';
import 'zone_details_screen.dart';

class FieldDetailScreen extends StatelessWidget {
  final String fieldId;
  const FieldDetailScreen({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final fieldIdx = state.fields.indexWhere((f) => f.id == fieldId);

    if (fieldIdx == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text("Field Details")),
        body: const Center(child: Text("Field details not found.")),
      );
    }

    final field = state.fields[fieldIdx];

    return Scaffold(
      appBar: AppBar(
        title: Text(field.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Master Connection status card
            _buildMasterCard(field),
            const SizedBox(height: 16),

            // 2. Zones card
            _buildZonesCard(context, field),
            const SizedBox(height: 16),

            // 3. Schedules card
            _buildSchedulesCard(state, field),
            const SizedBox(height: 16),

            // 4. Monitoring card
            _buildMonitoringCard(field),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterCard(Field field) {
    final mc = field.masterController;
    final bool isOnline = mc?.status == 'online';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Master Hub Info",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mc?.deviceUid ?? "Offline Controller",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOnline ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOnline ? "🟢 Online" : "🔴 Offline",
                    style: TextStyle(color: isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniSpecCol("Battery", "92%"),
                _miniSpecCol("Signal Status", "Excellent (-64dB)"),
                _miniSpecCol("Network Type", mc?.connectionType?.toUpperCase() ?? "GSM 4G"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _miniSpecCol(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildZonesCard(BuildContext context, Field field) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Zones",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            if (field.zones.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("No irrigation zones configured."),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: field.zones.length,
                separatorBuilder: (c, i) => const Divider(height: 16),
                itemBuilder: (context, idx) {
                  final z = field.zones[idx];
                  final bool isRunning = z.valves.any((v) => v.status == 'open');

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ZoneDetailScreen(fieldId: field.id, zoneId: z.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(z.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("${z.valves.length} Valves assigned", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isRunning ? Colors.green : Colors.grey.shade100).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isRunning ? "🟢 Running" : "⚪ Stopped",
                              style: TextStyle(
                                color: isRunning ? Colors.green : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesCard(AppState state, Field field) {
    final list = state.schedules.where((s) => s.fieldId == field.id).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Schedules",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("No irrigation schedules set."),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (c, i) => const Divider(height: 16),
                itemBuilder: (context, idx) {
                  final s = list[idx];
                  final bool isActive = s.status == 'active';

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            "Start: ${s.startTime} • ${s.durationMinutes} min",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFF00E676),
                        onChanged: (val) async {
                          await state.toggleScheduleStatus(s.id);
                        },
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringCard(Field field) {
    final mc = field.masterController;
    final tankLevel = mc?.tankLevel ?? 82;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Monitoring",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // Tank Level Visual Gauge
            const Text("Water Tank Storage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            TankLevelIndicator(level: tankLevel.toDouble()),
            const Divider(height: 24),

            // Soil Moisture Gauge
            const Text("Soil Moisture average", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 6),
            _meterBar(0.46, "46%"),
            const Divider(height: 24),

            // System Pressure stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _specMonitorVal("Drip System Pressure", "2.4 Bar"),
                _specMonitorVal("Telemetry Flow", "14.2 L/min"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _meterBar(double pct, String label) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2D7A3A)),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A), fontSize: 14),
        ),
      ],
    );
  }

  Widget _specMonitorVal(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A))),
      ],
    );
  }
}
