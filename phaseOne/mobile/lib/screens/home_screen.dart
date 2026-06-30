import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/field.dart';
import '../models/zone.dart';
import '../widgets/dashboard_metric_card.dart';
import 'field_details_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedFieldId;

  // AI Recommendation simulation
  bool _aiRecommendationApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadFields();
      state.loadAlerts();
      state.loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final fields = state.fields;

    if (fields.isEmpty) {
      return Scaffold(
        body: state.fieldsLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.landscape_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        "No farms/fields configured yet.",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => state.loadFields(),
                        child: const Text("REFRESH FIELDS"),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    if (_selectedFieldId == null || !fields.any((f) => f.id == _selectedFieldId)) {
      _selectedFieldId = fields.first.id;
    }

    final selectedField = fields.firstWhere((f) => f.id == _selectedFieldId);
    final mc = selectedField.masterController;
    final isOnline = mc?.status == 'online';
    final motorOn = mc?.motorStatus == 'on';

    // Find if any zone is running in the current field
    Zone? runningZone;
    for (var z in selectedField.zones) {
      if (z.valves.any((v) => v.status == 'open')) {
        runningZone = z;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await state.loadFields();
        await state.loadAlerts();
        await state.loadSchedules();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting & Farm Selection
            _buildGreeting(context, state, fields),
            const SizedBox(height: 16),

            // Master Controller Status Card
            _buildMasterStatus(state, selectedField),
            const SizedBox(height: 16),

            // Core Telemetry Metrics Grid (Tank, Moisture, Water Usage, Running Zone)
            _buildTelemetryGrid(context, state, selectedField, mc, runningZone),
            const SizedBox(height: 16),

            // Quick Start Card (UX recommendation)
            _buildQuickStartCard(context, state, selectedField, runningZone),
            const SizedBox(height: 16),

            // Fields list
            _buildFieldsList(context, fields),
            const SizedBox(height: 16),

            // AI recommendation widget
            _buildAIRecommendationWidget(state),
            const SizedBox(height: 16),

            // Recent alerts listing
            _buildRecentAlerts(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AppState state, List<Field> fields) {
    final userName = state.user?.name ?? "Farmer";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E4D2B), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E4D2B).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Good Morning 👋",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  userName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFieldId,
                dropdownColor: const Color(0xFF1E4D2B),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                items: fields.map((f) {
                  return DropdownMenuItem<String>(
                    value: f.id,
                    child: Text(f.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFieldId = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterStatus(AppState state, Field selectedField) {
    final mc = selectedField.masterController;
    final isOnline = mc?.status == 'online';
    final motorOn = mc?.motorStatus == 'on';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isOnline ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Master Hub status",
                    style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isOnline ? "🟢 Online" : "🔴 Offline",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (isOnline && mc != null) ...[
              const Text(
                "Motor: ",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Switch(
                value: motorOn,
                activeColor: const Color(0xFF00E676),
                onChanged: (val) async {
                  await state.controlMotor(mc.id, val ? 'start' : 'stop');
                },
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGrid(BuildContext context, AppState state, Field field, dynamic mc, Zone? runningZone) {
    final double cardWidth = (MediaQuery.of(context).size.width - 44) / 2;

    String runningText = "None";
    if (runningZone != null) {
      runningText = runningZone.name;
    } else if (mc?.motorStatus == 'on') {
      runningText = "Motor Running";
    }

    final tankLevel = mc?.tankLevel ?? 0;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Tank Card
        _buildTelemetryCard(
          width: cardWidth,
          icon: Icons.water_drop_rounded,
          iconColor: Colors.blue,
          title: "Tank Level",
          value: tankLevel > 0 ? "$tankLevel%" : "N/A",
          subtitle: tankLevel > 0 ? "Sensor Connected" : "No telemetry",
        ),
        // Soil Moisture (Simulated standard or average sensor if exists)
        _buildTelemetryCard(
          width: cardWidth,
          icon: Icons.grass,
          iconColor: Colors.orange,
          title: "Soil Moisture",
          value: "46%",
          subtitle: "Normal range",
        ),
        // Today's Water
        _buildTelemetryCard(
          width: cardWidth,
          icon: Icons.speed_rounded,
          iconColor: Colors.teal,
          title: "Today's Water",
          value: "1,200 L",
          subtitle: "Target: 1,500 L",
        ),
        // Running Zone
        _buildTelemetryCard(
          width: cardWidth,
          icon: Icons.timer,
          iconColor: runningZone != null ? Colors.green : Colors.grey,
          title: "Active Zone",
          value: runningText,
          subtitle: runningZone != null ? "Valves Open" : "System Idle",
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required double width,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartCard(BuildContext context, AppState state, Field field, Zone? runningZone) {
    final bool isRunning = runningZone != null;

    if (isRunning && runningZone != null) {
      return Card(
        color: const Color(0xFF1E4D2B),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        "IRRIGATING LIVE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "${field.name} • ${runningZone.name} Zone",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Irrigation cycle active. Tapping STOP will close the valves.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await state.executeCommand(targetType: 'zone', targetId: runningZone.id, action: 'close');
                },
                child: const Text("STOP IRRIGATION", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return QuickStartCardForm(field: field, state: state);
  }

  Widget _buildFieldsList(BuildContext context, List<Field> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Fields Overview",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B)),
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fields.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final f = fields[idx];
            final bool fRunning = f.zones.any((z) => z.valves.any((v) => v.status == 'open'));

            return Card(
              child: ListTile(
                leading: const Icon(Icons.landscape, color: Color(0xFF1E4D2B)),
                title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${f.zones.length} Zones • ${f.locationName ?? 'No location'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fRunning)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "ACTIVE",
                          style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => FieldDetailScreen(fieldId: f.id)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAIRecommendationWidget(AppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF00E676)),
              SizedBox(width: 8),
              Text(
                "AI Recommendation",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Soil moisture in North Farm Tomato block is low (46%). Increase morning shift duration by 10 minutes.",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _aiRecommendationApplied
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text("Applied Successfully", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00E676)),
                        foregroundColor: const Color(0xFF00E676),
                      ),
                      onPressed: () {
                        setState(() {
                          _aiRecommendationApplied = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("AI Recommendation Applied to schedule")),
                        );
                      },
                      child: const Text("Apply 10 min"),
                    ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(BuildContext context, AppState state) {
    final unreadAlerts = state.alerts.where((a) => !a.isRead).take(2).toList();
    if (unreadAlerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Alerts",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B)),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const NotificationsScreen()),
                );
              },
              child: const Text("View All", style: TextStyle(color: Color(0xFF1E4D2B))),
            )
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: unreadAlerts.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final a = unreadAlerts[idx];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(a.message ?? "", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => state.markAlertAsRead(a.id),
                    child: const Text("Dismiss", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class QuickStartCardForm extends StatefulWidget {
  final Field field;
  final AppState state;
  const QuickStartCardForm({super.key, required this.field, required this.state});

  @override
  State<QuickStartCardForm> createState() => _QuickStartCardFormState();
}

class _QuickStartCardFormState extends State<QuickStartCardForm> {
  String? _selectedZoneId;
  int _selectedDuration = 15;

  @override
  void initState() {
    super.initState();
    if (widget.field.zones.isNotEmpty) {
      _selectedZoneId = widget.field.zones.first.id;
    }
  }

  @override
  void didUpdateWidget(QuickStartCardForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.id != widget.field.id) {
      if (widget.field.zones.isNotEmpty) {
        _selectedZoneId = widget.field.zones.first.id;
      } else {
        _selectedZoneId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on, color: Color(0xFF1E4D2B)),
                SizedBox(width: 8),
                Text(
                  "Quick Start Irrigation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E4D2B)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.field.zones.isEmpty)
              const Text("No irrigation zones configured in this farm.")
            else ...[
              const Text("Select Zone Target", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedZoneId,
                    isExpanded: true,
                    items: widget.field.zones.map((z) {
                      return DropdownMenuItem<String>(
                        value: z.id,
                        child: Text(z.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedZoneId = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Duration", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text(
                    "$_selectedDuration Min",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B)),
                  ),
                ],
              ),
              Slider(
                value: _selectedDuration.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                activeColor: const Color(0xFF1E4D2B),
                inactiveColor: Colors.grey.shade200,
                onChanged: (val) {
                  setState(() {
                    _selectedDuration = val.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [5, 10, 15, 30, 45, 60].map((mins) {
                  bool isSel = _selectedDuration == mins;
                  return ChoiceChip(
                    label: Text("$mins m"),
                    selected: isSel,
                    selectedColor: const Color(0xFF1E4D2B),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDuration = mins;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              widget.state.commandLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_selectedZoneId != null) {
                          await widget.state.executeCommand(
                            targetType: 'zone',
                            targetId: _selectedZoneId!,
                            action: 'open',
                          );
                        }
                      },
                      child: const Text("START IRRIGATION NOW"),
                    )
            ],
          ],
        ),
      ),
    );
  }
}
