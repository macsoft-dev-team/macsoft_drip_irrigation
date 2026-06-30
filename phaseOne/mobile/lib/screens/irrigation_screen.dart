import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/field.dart';
import '../models/zone.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  String? _selectedFieldId;
  String? _selectedZoneId;
  int _selectedDuration = 30;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final fields = state.fields;

    // Detect if there is a running zone
    Field? runningField;
    Zone? runningZone;

    for (var f in fields) {
      for (var z in f.zones) {
        if (z.valves.any((v) => v.status == 'open')) {
          runningField = f;
          runningZone = z;
          break;
        }
      }
    }

    final bool isRunning = runningZone != null && runningField != null;

    if (isRunning) {
      return Container(
        padding: const EdgeInsets.all(28.0),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LiveIrrigationPulsar(),
            const SizedBox(height: 36),
            Text(
              runningZone!.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2D7A3A)),
            ),
            Text(
              "Active in ${runningField!.name}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("System State", "RUNNING"),
                  _buildStatColumn("Flow Rate", "14.2 L/min"),
                  _buildStatColumn("Pressure", "2.4 Bar"),
                ],
              ),
            ),
            const SizedBox(height: 48),
            state.commandLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: () async {
                          await state.executeCommand(
                            targetType: 'zone',
                            targetId: runningZone!.id,
                            action: 'close',
                          );
                        },
                        child: const Text("STOP IRRIGATION", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: () async {
                          await state.executeCommand(
                            targetType: 'zone',
                            targetId: runningZone!.id,
                            action: 'close',
                          );
                          if (runningField!.masterController != null) {
                            await state.controlMotor(runningField!.masterController!.id, 'stop');
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, color: Colors.white),
                            SizedBox(width: 8),
                            Text("EMERGENCY STOP"),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      );
    }

    if (fields.isEmpty) {
      return const Center(child: Text("No farms configured."));
    }

    if (_selectedFieldId == null || !fields.any((f) => f.id == _selectedFieldId)) {
      _selectedFieldId = fields.first.id;
    }
    final activeField = fields.firstWhere((f) => f.id == _selectedFieldId);

    if (_selectedZoneId == null || !activeField.zones.any((z) => z.id == _selectedZoneId)) {
      _selectedZoneId = activeField.zones.isNotEmpty ? activeField.zones.first.id : null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Start Irrigation",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D7A3A)),
          ),
          const SizedBox(height: 24),

          // 1. Select Field Card
          const Text("Select Field", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedFieldId,
                decoration: const InputDecoration(border: InputBorder.none, filled: false),
                items: fields.map((f) {
                  return DropdownMenuItem<String>(value: f.id, child: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedFieldId = val;
                    final f = fields.firstWhere((element) => element.id == val);
                    _selectedZoneId = f.zones.isNotEmpty ? f.zones.first.id : null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Select Zone Card
          const Text("Select Zone", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedZoneId,
                decoration: const InputDecoration(border: InputBorder.none, filled: false),
                items: activeField.zones.map((z) {
                  return DropdownMenuItem<String>(value: z.id, child: Text(z.name, style: const TextStyle(fontWeight: FontWeight.bold)));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedZoneId = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Select Duration
          const Text("Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [15, 30, 45, 60].map<Widget>((t) {
              bool isSel = _selectedDuration == t;
              return ChoiceChip(
                label: Text("$t min"),
                selected: isSel,
                selectedColor: const Color(0xFF2D7A3A),
                labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                onSelected: (bool selected) {
                  setState(() {
                    _selectedDuration = t;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 56),

          // 4. Start Button
          state.commandLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7A3A),
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    if (_selectedZoneId != null) {
                      await state.executeCommand(
                        targetType: 'zone',
                        targetId: _selectedZoneId!,
                        action: 'open',
                      );
                    }
                  },
                  child: const Text(
                    "START",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A))),
      ],
    );
  }
}

class LiveIrrigationPulsar extends StatefulWidget {
  const LiveIrrigationPulsar({super.key});

  @override
  State<LiveIrrigationPulsar> createState() => _LiveIrrigationPulsarState();
}

class _LiveIrrigationPulsarState extends State<LiveIrrigationPulsar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2D7A3A).withOpacity(0.05),
            border: Border.all(
              color: const Color(0xFF2D7A3A).withOpacity(1.0 - _controller.value),
              width: _controller.value * 20,
            ),
          ),
          child: const Center(
            child: Icon(Icons.water, size: 64, color: Color(0xFF2D7A3A)),
          ),
        );
      },
    );
  }
}
