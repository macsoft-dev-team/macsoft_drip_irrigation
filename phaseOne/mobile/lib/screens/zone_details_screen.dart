import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/zone.dart';
import '../models/valve.dart';
import 'schedules_screen.dart';

class ZoneDetailScreen extends StatefulWidget {
  final String fieldId;
  final String zoneId;
  const ZoneDetailScreen({super.key, required this.fieldId, required this.zoneId});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  int _selectedDuration = 30;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    final fieldIdx = state.fields.indexWhere((f) => f.id == widget.fieldId);
    if (fieldIdx == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text("Zone Details")),
        body: const Center(child: Text("Field not found")),
      );
    }
    final field = state.fields[fieldIdx];

    final zoneIdx = field.zones.indexWhere((z) => z.id == widget.zoneId);
    if (zoneIdx == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text("Zone Details")),
        body: const Center(child: Text("Zone not found")),
      );
    }
    final zone = field.zones[zoneIdx];
    final bool isRunning = zone.valves.any((v) => v.status == 'open');

    return Scaffold(
      appBar: AppBar(
        title: Text(zone.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Zone running header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isRunning ? const Color(0xFF2D7A3A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isRunning ? Colors.transparent : Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Text(
                    zone.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isRunning ? Colors.white : const Color(0xFF1E2A1F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRunning ? "🟢 Running" : "⚪ Stopped",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isRunning ? Colors.greenAccent : Colors.grey,
                    ),
                  ),
                  if (isRunning) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    const Text(
                      "Remaining",
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "18 Minutes",
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Valves List Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Valves",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: zone.valves.length,
                      separatorBuilder: (c, i) => const Divider(height: 12),
                      itemBuilder: (context, idx) {
                        final v = zone.valves[idx];
                        final bool vOpen = v.status == 'open';

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              v.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E2A1F)),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: vOpen ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Water Used Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Water Used",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRunning ? "320 L" : "0 L (Idle)",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D7A3A)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Interactive controls
            if (!isRunning) ...[
              const Text("Select Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [15, 30, 45, 60].map((mins) {
                  bool isSel = _selectedDuration == mins;
                  return ChoiceChip(
                    label: Text("$mins min"),
                    selected: isSel,
                    selectedColor: const Color(0xFF2D7A3A),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedDuration = mins;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            state.commandLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isRunning)
                        ElevatedButton(
                          onPressed: () async {
                            await state.executeCommand(
                              targetType: 'zone',
                              targetId: zone.id,
                              action: 'open',
                            );
                          },
                          child: const Text("Start"),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            await state.executeCommand(
                              targetType: 'zone',
                              targetId: zone.id,
                              action: 'close',
                            );
                          },
                          child: const Text("Stop"),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => ScheduleFormScreen(
                                initialFieldId: widget.fieldId,
                                initialTargetType: 'zone',
                                initialTargetId: widget.zoneId,
                              ),
                            ),
                          );
                        },
                        child: const Text("Edit Schedule"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
