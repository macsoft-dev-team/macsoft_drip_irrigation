import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/zone.dart';
import '../models/valve.dart';

class ZoneDetailScreen extends StatefulWidget {
  final String fieldId;
  final String zoneId;
  const ZoneDetailScreen({super.key, required this.fieldId, required this.zoneId});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  int _selectedDuration = 15;

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
      appBar: AppBar(title: Text("${zone.name} Details")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isRunning ? Colors.green.withOpacity(0.08) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isRunning ? Colors.green.withOpacity(0.3) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    isRunning ? Icons.play_circle_filled : Icons.pause_circle_filled,
                    size: 64,
                    color: isRunning ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRunning ? "STATUS: RUNNING" : "STATUS: IDLE / STOPPED",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isRunning ? Colors.green : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Valves List
            const Text(
              "Zone Valves Output List",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: zone.valves.length,
                itemBuilder: (context, idx) {
                  final v = zone.valves[idx];
                  final bool vOpen = v.status == 'open';

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.settings_input_component, color: Color(0xFF1E4D2B)),
                      title: Text(v.name),
                      subtitle: Text("Coil Index: ${v.valveNumber - 1} • State: ${v.status.toUpperCase()}"),
                      trailing: Switch(
                        value: vOpen,
                        activeColor: const Color(0xFF00E676),
                        onChanged: (val) async {
                          await state.executeCommand(
                            targetType: 'valve',
                            targetId: v.id,
                            action: val ? 'open' : 'close',
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Start/Stop controllers
            if (!isRunning) ...[
              const Text("Select Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [10, 20, 30, 45].map((t) {
                  bool isSel = _selectedDuration == t;
                  return ChoiceChip(
                    label: Text("$t Min"),
                    selected: isSel,
                    selectedColor: const Color(0xFF1E4D2B),
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDuration = t;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              state.commandLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        await state.executeCommand(
                          targetType: 'zone',
                          targetId: zone.id,
                          action: 'open',
                        );
                      },
                      child: const Text("START ZONE IRRIGATION"),
                    ),
            ] else ...[
              const SizedBox(height: 20),
              state.commandLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await state.executeCommand(
                          targetType: 'zone',
                          targetId: zone.id,
                          action: 'close',
                        );
                      },
                      child: const Text("STOP ZONE IRRIGATION"),
                    ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
