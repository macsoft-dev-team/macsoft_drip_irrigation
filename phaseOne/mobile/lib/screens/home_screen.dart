import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/app_state.dart';
import '../models/field.dart';
import '../models/zone.dart';
import '../widgets/tank_level_indicator.dart';
import '../widgets/animated_farm_scene.dart';
import 'field_details_screen.dart';
import 'notifications_screen.dart';
import 'support_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedFieldId;
  bool _aiRecommendationApplied = false;

  // Live Weather stats
  double _temp = 31.0;
  String _condition = "Sunny";
  String _humidity = "60%";
  String _wind = "12 km/h";
  bool _weatherLoading = false;

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() => _weatherLoading = true);
    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=30.9&longitude=75.85&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        final double temp = (current['temperature_2m'] as num).toDouble();
        final int humidity = (current['relative_humidity_2m'] as num).toInt();
        final double wind = (current['wind_speed_10m'] as num).toDouble();
        final int code = (current['weather_code'] as num).toInt();

        String condition = "Sunny";
        if (code >= 1 && code <= 3) condition = "Partly Cloudy";
        else if (code == 45 || code == 48) condition = "Foggy";
        else if (code >= 51 && code <= 55) condition = "Drizzle";
        else if (code >= 61 && code <= 65) condition = "Rainy";
        else if (code >= 80 && code <= 82) condition = "Showers";
        else if (code >= 95) condition = "Thunderstorm";

        if (mounted) {
          setState(() {
            _temp = temp;
            _condition = condition;
            _humidity = "$humidity%";
            _wind = "${wind.toStringAsFixed(1)} km/h";
            _weatherLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _weatherLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
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

    // Find if any zone is running in the current field
    Zone? runningZone;
    for (var z in selectedField.zones) {
      if (z.valves.any((v) => v.status == 'open')) {
        runningZone = z;
        break;
      }
    }

    final bool isHealthy = isOnline && state.alerts.where((a) => !a.isRead && a.severity == AlertSeverity.critical).isEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchWeather();
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
            // 1. Greet Section
            _buildGreetingHeader(state, selectedField, isOnline),
            const SizedBox(height: 16),

            // 2. Farm Snapshot (The top status centerpiece)
            _buildFarmSnapshotCard(selectedField, isHealthy, isOnline, runningZone),
            const SizedBox(height: 16),

            // 3. Current Irrigation Card (Pushed to top when active)
            if (runningZone != null) ...[
              _buildCurrentIrrigationCard(state, selectedField, runningZone),
              const SizedBox(height: 16),
            ],

            // 4. Quick Actions
            _buildQuickActions(context, state),
            const SizedBox(height: 16),

            // 5. Farm Status
            _buildFarmStatusCard(mc),
            const SizedBox(height: 16),

            // 6. Today's Summary
            _buildTodaySummaryCard(state),
            const SizedBox(height: 16),

            // 7. AI Recommendation
            _buildAIRecommendationWidget(state),
            const SizedBox(height: 16),

            // 8. Recent Alerts
            _buildRecentAlerts(context, state),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(AppState state, Field selectedField, bool isOnline) {
    final userName = state.user?.name ?? "John";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "👋 Good Morning, $userName",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D7A3A)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      selectedField.name,
                      style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isOnline ? Colors.green : Colors.red).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOnline ? "🟢 Master Online" : "🔴 Master Offline",
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Field Dropdown Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFieldId,
                items: Provider.of<AppState>(context, listen: false).fields.map((f) {
                  return DropdownMenuItem<String>(
                    value: f.id,
                    child: Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildFarmSnapshotCard(Field field, bool isHealthy, bool isOnline, Zone? runningZone) {
    final tankLevel = field.masterController?.tankLevel ?? 82;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  field.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E2A1F)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isHealthy ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isHealthy ? "🟢 Healthy" : "⚠️ Check Alert",
                    style: TextStyle(color: isHealthy ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _snapshotMiniInfo("Tank", "$tankLevel%"),
                _snapshotMiniInfo("Moisture", "45%"),
                _snapshotMiniInfo("Irrigation", runningZone != null ? "1 running" : "0 running"),
                _snapshotMiniInfo("Hub Link", isOnline ? "Online" : "Offline"),
              ],
            ),
            const Divider(height: 24, thickness: 0.8),
            Text(
              isHealthy ? "Everything looks good today." : "System requires action. Check alerts.",
              style: TextStyle(
                color: isHealthy ? const Color(0xFF2D7A3A) : Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _snapshotMiniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildCurrentIrrigationCard(AppState state, Field field, Zone runningZone) {
    return Card(
      color: const Color(0xFF2D7A3A),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_drop, color: Colors.greenAccent, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Current Irrigation",
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    runningZone.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "🟢 Running • 18 Minutes Remaining",
                    style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            state.commandLoading
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () async {
                      await state.executeCommand(
                        targetType: 'zone',
                        targetId: runningZone.id,
                        action: 'close',
                      );
                    },
                    child: const Text("Stop", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Quick Actions",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A)),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _actionBtn(Icons.play_circle_fill, "Start Irrigation", () => state.setTab(1)),
            _actionBtn(Icons.calendar_today, "Schedules", () => state.setTab(2)),
            _actionBtn(Icons.smart_toy, "AI Assistant", () => state.setTab(3)),
            _actionBtn(Icons.support_agent, "Support Center", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SupportScreen()),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2D7A3A), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2A1F)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmStatusCard(dynamic mc) {
    final tankLevel = mc?.tankLevel ?? 82;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Farm Status",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A)),
            ),
            const SizedBox(height: 14),
            _statusRow("💧 Tank Level", "$tankLevel%"),
            _statusRow("🌿 Soil Moisture", "45%"),
            _statusRow("🌡 Temperature", "${_temp.toStringAsFixed(0)}°C"),
            _statusRow("☀️ Sky Weather", _condition),
            const SizedBox(height: 16),
            // Embed wobbly tractor animation at the bottom of status panel
            SizedBox(
              height: 105,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const AnimatedFarmScene(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A))),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard(AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryInfoCol("Water Used", "1,200 L"),
                _summaryInfoCol("Runtime", "3h 12m"),
                _summaryInfoCol("Schedules", "${state.schedules.length}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryInfoCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D7A3A))),
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
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Moisture is lower than yesterday. Increase morning shift irrigation by 10 minutes.",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _aiRecommendationApplied
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text("Applied", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: const Color(0xFF2D7A3A),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () {
                        setState(() {
                          _aiRecommendationApplied = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Irrigation duration increased by 10m.")),
                        );
                      },
                      child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(BuildContext context, AppState state) {
    // Expose alerts list
    final alerts = state.alerts.take(2).toList();
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Alerts",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A)),
            ),
            TextButton(
              onPressed: () => state.setTab(2), // jump to alert/notifications area or schedules
              child: const Text("View All", style: TextStyle(color: Color(0xFF2D7A3A))),
            )
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alerts.length,
          separatorBuilder: (c, i) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final a = alerts[idx];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    a.severity == AlertSeverity.critical ? Icons.error_outline : Icons.warning_amber_rounded,
                    color: a.severity == AlertSeverity.critical ? Colors.red : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
