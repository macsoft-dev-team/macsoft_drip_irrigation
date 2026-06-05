import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/field.dart';
import '../widgets/status_chip.dart';
import '../widgets/confirm_action_dialog.dart';
import 'master_controller_detail_screen.dart';
import 'zone_detail_screen.dart';
import 'schedule_list_screen.dart';
import 'command_status_screen.dart';

class FieldDetailScreen extends StatelessWidget {
  final String fieldId;
  const FieldDetailScreen({super.key, required this.fieldId});

  Future<void> _openAllZones(BuildContext context, Field field) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Open All Zones',
      content: 'Are you sure you want to open all valves in all zones of "${field.name}"?',
    );

    if (confirmed && context.mounted) {
      final state = context.read<AppState>();
      for (var zone in field.zones) {
        await state.executeCommand(targetType: 'zone', targetId: zone.id, action: 'open');
      }
      if (context.mounted && state.activeCommand != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommandStatusScreen(commandId: state.activeCommand!.id),
          ),
        );
      }
    }
  }

  Future<void> _closeAllZones(BuildContext context, Field field) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'Close All Zones',
      content: 'Are you sure you want to close all valves in all zones of "${field.name}"?',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final state = context.read<AppState>();
      for (var zone in field.zones) {
        await state.executeCommand(targetType: 'zone', targetId: zone.id, action: 'close');
      }
      if (context.mounted && state.activeCommand != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommandStatusScreen(commandId: state.activeCommand!.id),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () async {
              final confirmed = await ConfirmActionDialog.show(
                context,
                title: 'Delete Field',
                content: 'Are you sure you want to delete this field? This action cannot be undone.',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                final ok = await context.read<AppState>().deleteField(fieldId);
                if (ok && context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          )
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final fieldIdx = state.fields.indexWhere((f) => f.id == fieldId);
          if (fieldIdx == -1) {
            return const Center(child: Text('Field not found'));
          }
          final field = state.fields[fieldIdx];

          final int totalValves = field.zones.fold(0, (sum, z) => sum + z.valves.length);
          final int openValves = field.zones.fold(0, (sum, z) => sum + z.valves.where((v) => v.status == 'open').length);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header details
                Text(
                  field.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF8A958A)),
                    const SizedBox(width: 4),
                    Text(field.locationName ?? 'No location details', style: const TextStyle(color: Color(0xFF8A958A))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.aspect_ratio_rounded, size: 16, color: Color(0xFF8A958A)),
                    const SizedBox(width: 4),
                    Text('${field.areaAcres ?? 0.0} Acres', style: const TextStyle(color: Color(0xFF8A958A))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, size: 16, color: Color(0xFF8A958A)),
                    const SizedBox(width: 4),
                    Text('$openValves / $totalValves Valves Active', style: const TextStyle(color: Color(0xFF8A958A))),
                  ],
                ),
                const SizedBox(height: 20),

                // Master controller card
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.router_rounded, color: Color(0xFF2D7A3A), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.masterController?.deviceUid ?? 'No Controller Linked',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                field.masterController?.isOnline == true ? 'Online · Connected' : 'Offline · Disconnected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: field.masterController?.isOnline == true ? const Color(0xFF2D7A3A) : const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (field.masterController != null)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MasterControllerDetailScreen(
                                    masterController: field.masterController!,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(60, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('View', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bulk controls
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: field.masterController?.isOnline == true ? () => _openAllZones(context, field) : null,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Open All'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D7A3A)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: field.masterController?.isOnline == true ? () => _closeAllZones(context, field) : null,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Close All'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ),
                if (field.masterController?.isOnline != true) ...[
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Bulk commands disabled: Master Controller is offline.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Zones list section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Irrigation Zones (${field.zones.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ZoneFormScreen(fieldId: field.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Zone', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D7A3A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (field.zones.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.layers_clear_outlined, size: 36, color: Color(0xFF8A958A)),
                        SizedBox(height: 12),
                        Text('No zones added yet.', style: TextStyle(fontSize: 13, color: Color(0xFF8A958A))),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: field.zones.length,
                    itemBuilder: (context, idx) {
                      final zone = field.zones[idx];
                      final activeValves = zone.valves.where((v) => v.status == 'open').length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ZoneDetailScreen(
                                  zoneId: zone.id,
                                  fieldId: field.id,
                                ),
                              ),
                            );
                          },
                          title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${zone.valves.length} Valves · $activeValves Active',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A)),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCBD5E1)),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
