import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/field.dart';
import '../models/zone.dart';
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
    final bool isRunning = field.zones.any((z) => z.valves.any((v) => v.status == 'open'));

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(field.name),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF1E4D2B),
            labelColor: Color(0xFF1E4D2B),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Zones"),
              Tab(text: "Monitoring"),
              Tab(text: "Schedules"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(context, state, field, isRunning),
            _buildZonesTab(context, state, field),
            _buildMonitoringTab(context, state, field),
            _buildSchedulesTab(context, state, field),
            _buildHistoryTab(context, state, field),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, AppState state, Field field, bool isRunning) {
    final mc = field.masterController;
    final isOnline = mc?.status == 'online';

    // Find first open zone
    String runningZoneName = "None";
    for (var z in field.zones) {
      if (z.valves.any((v) => v.status == 'open')) {
        runningZoneName = z.name;
        break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Icon(Icons.landscape, size: 48, color: Color(0xFF1E4D2B)),
                const SizedBox(height: 12),
                Text(field.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  "Area size: ${field.areaAcres ?? 0.0} Acres • Location: ${field.locationName ?? 'Not set'}",
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewIndicator("Master Controller", isOnline ? "🟢 Online" : "🔴 Offline"),
                    _buildOverviewIndicator("Running Zone", runningZoneName),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewIndicator("Water Used Today", "1,200 L"),
                    _buildOverviewIndicator("System Pressure", "2.4 Bar (Normal)"),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOverviewIndicator(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildZonesTab(BuildContext context, AppState state, Field field) {
    if (field.zones.isEmpty) {
      return const Center(child: Text("No zones configured."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: field.zones.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final z = field.zones[idx];
        final bool isRunning = z.valves.any((v) => v.status == 'open');

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.grid_on,
              color: isRunning ? Colors.green : Colors.grey,
              size: 28,
            ),
            title: Text(z.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${z.valves.length} Valves assigned (${z.status})"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isRunning ? Colors.green : Colors.grey.shade200).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isRunning ? "RUNNING" : "STOPPED",
                style: TextStyle(
                  color: isRunning ? Colors.green : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ZoneDetailScreen(fieldId: field.id, zoneId: z.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMonitoringTab(BuildContext context, AppState state, Field field) {
    final mc = field.masterController;
    final tankLevel = mc?.tankLevel ?? 0;
    final isOnline = mc?.status == 'online';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonitorRow("Water Tank Capacity", tankLevel > 0 ? "$tankLevel%" : "Sensor Offline", Icons.water_drop, Colors.blue),
          _buildMonitorRow("Drip System Pressure", "2.4 Bar (Normal)", Icons.speed, Colors.purple),
          _buildMonitorRow("Flow Rate Sensor", "14.2 L/min", Icons.compare_arrows, Colors.teal),
          _buildMonitorRow("Soil Moisture Sensor", "46% (Moisture Low)", Icons.grass, Colors.orange),
          _buildMonitorRow("Master Controller Connection", isOnline ? "Heartbeat Ok" : "Disconnected", Icons.wifi, Colors.green),
          _buildMonitorRow("Slaves Signals RSSI", "Excellent (-64 dBm)", Icons.settings_input_antenna, Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildMonitorRow(String name, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B)),
        ),
      ),
    );
  }

  Widget _buildSchedulesTab(BuildContext context, AppState state, Field field) {
    final list = state.schedules.where((s) => s.fieldId == field.id).toList();

    if (list.isEmpty) {
      return const Center(child: Text("No schedules configured for this field."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final sch = list[idx];
        final isActive = sch.status == 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(sch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              "Start: ${sch.startTime} • Duration: ${sch.durationMinutes} min\nRepeat: ${sch.repeatDays.join(', ')}",
            ),
            trailing: Switch(
              value: isActive,
              activeColor: const Color(0xFF00E676),
              onChanged: (val) async {
                await state.toggleScheduleStatus(sch.id);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context, AppState state, Field field) {
    // Return standard mock logging items for the field
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHistoryItem("Today", "Tomato Block Run", "45 min cycle complete", "1,800 L used", true),
        _buildHistoryItem("Yesterday", "Banana Section Run", "20 min cycle complete", "950 L used", true),
        _buildHistoryItem("June 28", "Cotton Row Run", "30 min cycle complete", "1,200 L used", true),
        _buildHistoryItem("June 26", "Tomato Block Run", "Automatic cycle error (Valve mismatch)", "250 L used", false),
      ],
    );
  }

  Widget _buildHistoryItem(String time, String title, String desc, String quantity, bool isSuccess) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(desc, style: const TextStyle(fontSize: 12))),
            Text(quantity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B))),
          ],
        ),
      ),
    );
  }
}
