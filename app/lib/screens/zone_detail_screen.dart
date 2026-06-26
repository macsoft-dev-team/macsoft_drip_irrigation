import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/zone.dart';
import '../models/valve.dart';
import '../widgets/zone_card.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/app_loading_button.dart';
import '../widgets/app_text_field.dart';
import 'valve_detail_screen.dart';
import 'command_status_screen.dart';
import 'schedule_list_screen.dart';

class ZoneDetailScreen extends StatelessWidget {
  final String zoneId;
  final String fieldId;

  const ZoneDetailScreen({
    super.key,
    required this.zoneId,
    required this.fieldId,
  });

  Future<void> _triggerZoneCommand(
    BuildContext context,
    Zone zone,
    String action,
  ) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: action == 'open' ? 'Open Zone' : 'Close Zone',
      content: action == 'open'
          ? 'Open all valves in "${zone.name}"?'
          : 'Close all valves in "${zone.name}"?',
      isDestructive: action == 'close',
    );

    if (confirmed && context.mounted) {
      final state = context.read<AppState>();
      await state.executeCommand(
        targetType: 'zone',
        targetId: zone.id,
        action: action,
      );
      if (context.mounted && state.activeCommand != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CommandStatusScreen(commandId: state.activeCommand!.id),
          ),
        );
      }
    }
  }

  Future<void> _triggerValveCommand(
    BuildContext context,
    Valve valve,
    String action,
  ) async {
    final state = context.read<AppState>();
    await state.executeCommand(
      targetType: 'valve',
      targetId: valve.id,
      action: action,
    );
    if (context.mounted && state.activeCommand != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CommandStatusScreen(commandId: state.activeCommand!.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ZoneFormScreen(fieldId: fieldId, zoneId: zoneId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () async {
              final confirmed = await ConfirmActionDialog.show(
                context,
                title: 'Delete Zone',
                content:
                    'Are you sure you want to delete this zone and all its valves? This cannot be undone.',
                isDestructive: true,
              );
              if (confirmed && context.mounted) {
                final ok = await context.read<AppState>().deleteZone(
                  zoneId,
                  fieldId,
                );
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
          if (fieldIdx == -1)
            return const Center(child: Text('Field not found'));
          final field = state.fields[fieldIdx];

          final zoneIdx = field.zones.indexWhere((z) => z.id == zoneId);
          if (zoneIdx == -1) return const Center(child: Text('Zone not found'));
          final zone = field.zones[zoneIdx];

          final bool isMCActive = field.masterController?.isOnline ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ZoneCard(
              zone: zone,
              isMasterOnline: isMCActive,
              onValveOpen: (v) => _triggerValveCommand(context, v, 'open'),
              onValveClose: (v) => _triggerValveCommand(context, v, 'close'),
              onValveTap: (v) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ValveDetailScreen(
                      valveId: v.id,
                      zoneId: zone.id,
                      fieldId: field.id,
                    ),
                  ),
                );
              },
              onOpenZone: () => _triggerZoneCommand(context, zone, 'open'),
              onCloseZone: () => _triggerZoneCommand(context, zone, 'close'),
              onAddValve: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ValveFormScreen(fieldId: field.id, zoneId: zone.id),
                  ),
                );
              },
              onCreateSchedule: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleFormScreen(
                      initialFieldId: fieldId,
                      initialTargetType: 'zone',
                      initialTargetId: zone.id,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ZoneFormScreen extends StatefulWidget {
  final String fieldId;
  final String? zoneId;
  const ZoneFormScreen({super.key, required this.fieldId, this.zoneId});

  @override
  State<ZoneFormScreen> createState() => _ZoneFormScreenState();
}

class _ZoneFormScreenState extends State<ZoneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();

    if (widget.zoneId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = context.read<AppState>();
        final field = state.fields.firstWhere((f) => f.id == widget.fieldId);
        final zone = field.zones.firstWhere((z) => z.id == widget.zoneId);
        setState(() {
          _nameController.text = zone.name;
          _descController.text = zone.description ?? '';
        });
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveZone() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final state = context.read<AppState>();
    bool ok;

    if (widget.zoneId == null) {
      ok = await state.createZone(
        fieldId: widget.fieldId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
      );
    } else {
      ok = await state.updateZone(
        id: widget.zoneId!,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        fieldId: widget.fieldId,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.zoneId == null
                ? 'Zone created successfully'
                : 'Zone updated successfully',
          ),
          backgroundColor: const Color(0xFF2D7A3A),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.zoneId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Zone' : 'Add Zone')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              AppTextField(
                label: 'Zone Name',
                hint: 'e.g. Zone A (High Flow)',
                controller: _nameController,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Zone name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'e.g. Covers east section of sugarcane block',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              AppLoadingButton(
                label: isEdit ? 'Update Zone' : 'Save Zone',
                isLoading: _isLoading,
                onPressed: _saveZone,
                color: const Color(0xFF2D7A3A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
