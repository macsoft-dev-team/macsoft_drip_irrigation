import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'field_details_screen.dart';

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final fields = state.fields;

    return Scaffold(
      appBar: AppBar(title: const Text("Fields / Farms")),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.loadFields();
        },
        child: fields.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.landscape_rounded, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text("No fields configured.", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => state.loadFields(),
                      child: const Text("REFRESH"),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: fields.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final f = fields[idx];
                  final bool isRunning = f.zones.any((z) => z.valves.any((v) => v.status == 'open'));
                  final activeValvesCount = f.zones.fold<int>(
                    0,
                    (sum, z) => sum + z.valves.where((v) => v.status == 'open').length,
                  );

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E4D2B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.landscape_rounded, color: Color(0xFF1E4D2B)),
                      ),
                      title: Text(
                        f.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        "${f.zones.length} Zones configured • ${f.areaAcres ?? 0.0} Acres\nStatus: ${f.status.toUpperCase()}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRunning)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "$activeValvesCount Valves Running",
                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => FieldDetailScreen(fieldId: f.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
