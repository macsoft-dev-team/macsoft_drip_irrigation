import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/field.dart';
import '../models/zone.dart';
import '../models/valve.dart';
import '../models/app_user.dart';

class IrrigationPage extends StatefulWidget {
  const IrrigationPage({super.key});

  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage> {
  final Map<String, bool> _expandedFields = {};
  final Map<String, bool> _expandedZones = {};
  List<Map<String, dynamic>> _customers = [];
  bool _loadingCustomers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadFields();
      _fetchCustomersIfNeeded();
    });
  }

  Future<void> _fetchCustomersIfNeeded() async {
    final state = context.read<AppState>();
    if (state.user?.role == UserRole.superadmin) {
      setState(() => _loadingCustomers = true);
      try {
        final api = state.api;
        if (api != null) {
          final list = await api.getCustomers();
          setState(() => _customers = list);
        }
      } catch (_) {}
      setState(() => _loadingCustomers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Irrigation Fields'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AppState>().loadFields(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            onPressed: () => _showFieldFormSheet(context),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.fieldsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.fieldsError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.fieldsError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => state.loadFields(),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }
          if (state.fields.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.grid_on_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No fields found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to create your first field.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showFieldFormSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Field'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 48),
                    ),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => state.loadFields(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: state.fields.length,
              itemBuilder: (context, idx) {
                final field = state.fields[idx];
                final isExpanded = _expandedFields[field.id] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE3F2FD),
                          child: Icon(Icons.landscape_rounded, color: Color(0xFF1565C0)),
                        ),
                        title: Text(
                          field.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: state.user?.role == UserRole.superadmin
                            ? Text('ID: ${field.id}', style: const TextStyle(fontSize: 11))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showFieldFormSheet(context, field: field),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                              onPressed: () => _confirmDeleteField(context, field),
                            ),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _expandedFields[field.id] = !isExpanded;
                          });
                        },
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildZonesList(context, field),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFieldFormSheet(context),
        label: const Text('New Field'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildZonesList(BuildContext context, Field field) {
    if (field.zones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'No zones in this field',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _showZoneFormSheet(context, field),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Zone'),
            )
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          ...field.zones.map((zone) {
            final isExpanded = _expandedZones[zone.id] ?? false;

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                  leading: const Icon(Icons.grid_goldenratio_rounded, color: Colors.green, size: 20),
                  title: Text(
                    zone.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showZoneFormSheet(context, field, zone: zone),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        onPressed: () => _confirmDeleteZone(context, field, zone),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _expandedZones[zone.id] = !isExpanded;
                    });
                  },
                ),
                if (isExpanded) ...[
                  const Divider(height: 1, indent: 48, endIndent: 16),
                  _buildValvesList(context, field, zone),
                ],
              ],
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: () => _showZoneFormSheet(context, field),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Zone', style: TextStyle(fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildValvesList(BuildContext context, Field field, Zone zone) {
    if (zone.valves.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'No valves in this zone',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showValveFormSheet(context, field, zone),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Valve', style: TextStyle(fontSize: 12)),
            )
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          ...zone.valves.map((valve) {
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 48, right: 16),
              leading: const Icon(Icons.water_drop_outlined, color: Colors.blue, size: 16),
              title: Text(
                valve.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: () => _showValveFormSheet(context, field, zone, valve: valve),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                    onPressed: () => _confirmDeleteValve(context, field, zone, valve),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextButton.icon(
              onPressed: () => _showValveFormSheet(context, field, zone),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Valve', style: TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  // ── Form sheets ──────────────────────────────────────────────────────────

  void _showFieldFormSheet(BuildContext context, {Field? field}) {
    final state = context.read<AppState>();
    final isEdit = field != null;
    final controller = TextEditingController(text: field?.name);
    String? selectedCustomerId = field?.customerId ?? (state.user?.customerId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isSuperadmin = state.user?.role == UserRole.superadmin;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Field' : 'Create New Field',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Field Name',
                      hintText: 'e.g., North Orchard',
                    ),
                    autofocus: true,
                  ),
                  if (isSuperadmin && !isEdit) ...[
                    const SizedBox(height: 16),
                    _loadingCustomers
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: selectedCustomerId,
                            decoration: const InputDecoration(labelText: 'Assign to Customer'),
                            items: _customers.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['id'].toString(),
                                child: Text(c['name'] ?? c['email'] ?? c['id']),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setModalState(() {
                                selectedCustomerId = val;
                              });
                            },
                          ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      if (selectedCustomerId == null) return;

                      bool success;
                      if (isEdit) {
                        success = await state.updateField(field.id, name);
                      } else {
                        success = await state.createField(name, selectedCustomerId!);
                      }

                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isEdit ? 'Field updated' : 'Field created')),
                        );
                      }
                    },
                    child: Text(isEdit ? 'Save Changes' : 'Create Field'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showZoneFormSheet(BuildContext context, Field field, {Zone? zone}) {
    final state = context.read<AppState>();
    final isEdit = zone != null;
    final controller = TextEditingController(text: zone?.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Zone' : 'Add Zone to ${field.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Zone Name',
                  hintText: 'e.g., Tomato Patch',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;

                  bool success;
                  if (isEdit) {
                    success = await state.updateZone(zone.id, name, field.id);
                  } else {
                    success = await state.createZone(name, field.id);
                  }

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Zone updated' : 'Zone added')),
                    );
                  }
                },
                child: Text(isEdit ? 'Save Changes' : 'Add Zone'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showValveFormSheet(BuildContext context, Field field, Zone zone, {Valve? valve}) {
    final state = context.read<AppState>();
    final isEdit = valve != null;
    final controller = TextEditingController(text: valve?.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Valve' : 'Add Valve to ${zone.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Valve Name',
                  hintText: 'e.g., Solenoid 1',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;

                  bool success;
                  if (isEdit) {
                    success = await state.updateValve(valve.id, name, zone.id, field.id);
                  } else {
                    success = await state.createValve(name, zone.id, field.id);
                  }

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Valve updated' : 'Valve added')),
                    );
                  }
                },
                child: Text(isEdit ? 'Save Changes' : 'Add Valve'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Confirm deletion dialogs ───────────────────────────────────────────

  void _confirmDeleteField(BuildContext context, Field field) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Field?'),
          content: Text('Are you sure you want to delete "${field.name}"? This will delete all zones and valves inside it.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final success = await context.read<AppState>().deleteField(field.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Field deleted')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteZone(BuildContext context, Field field, Zone zone) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Zone?'),
          content: Text('Are you sure you want to delete "${zone.name}"? This will delete all valves inside it.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final success = await context.read<AppState>().deleteZone(zone.id, field.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zone deleted')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteValve(BuildContext context, Field field, Zone zone, Valve valve) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Valve?'),
          content: Text('Are you sure you want to delete "${valve.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final success = await context.read<AppState>().deleteValve(valve.id, zone.id, field.id);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Valve deleted')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
