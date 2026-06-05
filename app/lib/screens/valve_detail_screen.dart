import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/valve.dart';
import '../widgets/status_chip.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/app_loading_button.dart';
import '../widgets/app_text_field.dart';
import 'command_status_screen.dart';
import 'support_screen.dart';

class ValveDetailScreen extends StatelessWidget {
  final String valveId;
  final String zoneId;
  final String fieldId;

  const ValveDetailScreen({
    super.key,
    required this.valveId,
    required this.zoneId,
    required this.fieldId,
  });

  Future<void> _triggerValveCommand(BuildContext context, Valve valve, String action) async {
    final state = context.read<AppState>();
    await state.executeCommand(targetType: 'valve', targetId: valve.id, action: action);
    if (context.mounted && state.activeCommand != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommandStatusScreen(commandId: state.activeCommand!.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valve Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ValveFormScreen(fieldId: fieldId, zoneId: zoneId, valveId: valveId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () async {
              final confirmed = await ConfirmActionDialog.show(
                context,
                title: 'Delete Valve',
                content: 'Are you sure you want to delete this valve? This cannot be undone.',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                final ok = await context.read<AppState>().deleteValve(valveId, zoneId, fieldId);
                if (ok && context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final fieldIdx = state.fields.indexWhere((f) => f.id == fieldId);
          if (fieldIdx == -1) return const Center(child: Text('Field not found'));
          final field = state.fields[fieldIdx];

          final zoneIdx = field.zones.indexWhere((z) => z.id == zoneId);
          if (zoneIdx == -1) return const Center(child: Text('Zone not found'));
          final zone = field.zones[zoneIdx];

          final valveIdx = zone.valves.indexWhere((v) => v.id == valveId);
          if (valveIdx == -1) return const Center(child: Text('Valve not found'));
          final valve = zone.valves[valveIdx];

          final bool isMCActive = field.masterController?.isOnline ?? false;
          final bool isOpen = valve.status == 'open';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.water_drop, color: Color(0xFF2D7A3A), size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valve.name,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E2A1F)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Status: ', style: TextStyle(fontSize: 12, color: Color(0xFF8A958A))),
                                StatusChip(status: valve.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Hardware Info Card
                const Text(
                  'Valve Configuration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _SpecRow(label: 'Valve Number', value: '#${valve.valveNumber}'),
                        _SpecRow(label: 'Device UID', value: valve.deviceUid),
                        _SpecRow(label: 'Zone', value: zone.name),
                        _SpecRow(
                          label: 'Installed At',
                          value: valve.installedAt != null
                              ? valve.installedAt!.toLocal().toString().substring(0, 16)
                              : 'N/A',
                        ),
                        _SpecRow(
                          label: 'Last Changed',
                          value: valve.lastStatusAt != null
                              ? valve.lastStatusAt!.toLocal().toString().substring(0, 16)
                              : 'Never',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Command History Placeholder
                const Text(
                  'Command History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.check, color: Color(0xFF2D7A3A), size: 18),
                        ),
                        title: Text('Opened successfully by schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('Today · 06:00 AM', style: TextStyle(fontSize: 11, color: Color(0xFF8A958A))),
                      ),
                      Divider(height: 1, thickness: 0.8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.check, color: Color(0xFF2D7A3A), size: 18),
                        ),
                        title: Text('Closed successfully by farmer command', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text('Yesterday · 07:15 PM', style: TextStyle(fontSize: 11, color: Color(0xFF8A958A))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isMCActive ? () => _triggerValveCommand(context, valve, isOpen ? 'close' : 'open') : null,
                        icon: Icon(isOpen ? Icons.stop_rounded : Icons.play_arrow_rounded),
                        label: Text(isOpen ? 'Close Valve' : 'Open Valve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOpen ? const Color(0xFFDC2626) : const Color(0xFF2D7A3A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SupportTicketFormScreen(
                                initialValveId: valve.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bug_report_outlined),
                        label: const Text('Report Issue'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isMCActive) ...[
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Commands queued: Master Controller is offline.',
                      style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class ValveFormScreen extends StatefulWidget {
  final String fieldId;
  final String zoneId;
  final String? valveId;

  const ValveFormScreen({
    super.key,
    required this.fieldId,
    required this.zoneId,
    this.valveId,
  });

  @override
  State<ValveFormScreen> createState() => _ValveFormScreenState();
}

class _ValveFormScreenState extends State<ValveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _uidController;
  late TextEditingController _numberController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _uidController = TextEditingController();
    _numberController = TextEditingController();

    if (widget.valveId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = context.read<AppState>();
        final field = state.fields.firstWhere((f) => f.id == widget.fieldId);
        final zone = field.zones.firstWhere((z) => z.id == widget.zoneId);
        final valve = zone.valves.firstWhere((v) => v.id == widget.valveId);
        setState(() {
          _nameController.text = valve.name;
          _uidController.text = valve.deviceUid;
          _numberController.text = valve.valveNumber.toString();
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _uidController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _saveValve() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final state = context.read<AppState>();
    bool ok;

    if (widget.valveId == null) {
      ok = await state.createValve(
        zoneId: widget.zoneId,
        deviceUid: _uidController.text.trim(),
        name: _nameController.text.trim(),
        valveNumber: int.parse(_numberController.text),
        fieldId: widget.fieldId,
      );
    } else {
      ok = await state.updateValve(
        id: widget.valveId!,
        name: _nameController.text.trim(),
        valveNumber: int.parse(_numberController.text),
        zoneId: widget.zoneId,
        fieldId: widget.fieldId,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.valveId == null ? 'Valve created successfully' : 'Valve updated successfully'),
          backgroundColor: const Color(0xFF2D7A3A),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.valveId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Valve' : 'Add Valve'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              AppTextField(
                label: 'Valve Name',
                hint: 'e.g. Line 1 Solenoid',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Valve name is required' : null,
              ),
              const SizedBox(height: 16),
              if (!isEdit) ...[
                AppTextField(
                  label: 'Device UID',
                  hint: 'e.g. VALVE-A1-NODE',
                  controller: _uidController,
                  validator: (v) => v == null || v.isEmpty ? 'Device UID is required' : null,
                ),
                const SizedBox(height: 16),
              ],
              AppTextField(
                label: 'Valve Number / Position Index',
                hint: 'e.g. 1',
                controller: _numberController,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'Enter valid number' : null,
              ),
              const SizedBox(height: 32),
              AppLoadingButton(
                label: isEdit ? 'Update Valve' : 'Save Valve',
                isLoading: _isLoading,
                onPressed: _saveValve,
                color: const Color(0xFF2D7A3A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A958A), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E2A1F), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
