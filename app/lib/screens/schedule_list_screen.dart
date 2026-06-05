import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/irrigation_schedule.dart';
import '../models/field.dart';
import '../models/valve.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_loading_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/confirm_action_dialog.dart';

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadSchedules();
      context.read<AppState>().loadFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigation Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm_rounded, color: Color(0xFF2D7A3A), size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScheduleFormScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.schedulesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.schedules.isEmpty) {
            return EmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No Schedules Found',
              description: 'Schedule automated irrigation timings to deliver water to your crops efficiently.',
              actionLabel: 'Create Schedule',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScheduleFormScreen()),
                );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () => state.loadSchedules(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: state.schedules.length,
              itemBuilder: (context, index) {
                final sched = state.schedules[index];
                final field = state.fields.firstWhere((f) => f.id == sched.fieldId, orElse: () => state.fields.isNotEmpty ? state.fields[0] : _dummyField());

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                sched.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E2A1F)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Switch(
                              value: sched.isActive,
                              activeColor: const Color(0xFF2D7A3A),
                              onChanged: (val) async {
                                final ok = await state.toggleScheduleStatus(sched.id);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to update schedule status.')),
                                  );
                                }
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Field: ${field.name}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A)),
                        ),
                        Text(
                          'Target: ${sched.targetType.toUpperCase()} · ${sched.targetName ?? sched.targetId}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A)),
                        ),
                        const Divider(height: 20, thickness: 0.8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF2D7A3A)),
                                const SizedBox(width: 4),
                                Text(
                                  '${sched.startTime} (${sched.durationMinutes} mins)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            StatusChip(status: sched.repeatType),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF8A958A), size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScheduleFormScreen(schedule: sched),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () async {
                                final confirmed = await ConfirmActionDialog.show(
                                  context,
                                  title: 'Delete Schedule',
                                  content: 'Are you sure you want to delete this irrigation schedule?',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  await state.deleteSchedule(sched.id);
                                }
                              },
                            )
                          ],
                        )
                      ],
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

  Field _dummyField() {
    return Field(id: '0', farmerId: '0', name: 'Unknown Field', status: 'inactive');
  }
}

class ScheduleFormScreen extends StatefulWidget {
  final IrrigationSchedule? schedule;
  final String? initialTargetType;
  final String? initialTargetId;

  const ScheduleFormScreen({
    super.key,
    this.schedule,
    this.initialTargetType,
    this.initialTargetId,
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _durationController;

  String? _selectedFieldId;
  String _targetType = 'zone'; // zone, valve
  String? _selectedTargetId;
  String _startTime = '06:00';
  String _repeatType = 'daily'; // once, daily, weekly, customDays
  List<String> _repeatDays = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schedule?.name ?? '');
    _durationController = TextEditingController(
      text: widget.schedule?.durationMinutes.toString() ?? '30',
    );

    if (widget.schedule != null) {
      _selectedFieldId = widget.schedule!.fieldId;
      _targetType = widget.schedule!.targetType;
      _selectedTargetId = widget.schedule!.targetId;
      _startTime = widget.schedule!.startTime;
      _repeatType = widget.schedule!.repeatType;
      _repeatDays = widget.schedule!.repeatDays;
    } else {
      _targetType = widget.initialTargetType ?? 'zone';
      _selectedTargetId = widget.initialTargetId;
      
      // Auto-select first field if available
      final state = context.read<AppState>();
      if (state.fields.isNotEmpty) {
        _selectedFieldId = state.fields[0].id;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final curParts = _startTime.split(':');
    final curHour = int.tryParse(curParts[0]) ?? 6;
    final curMin = int.tryParse(curParts[1]) ?? 0;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: curHour, minute: curMin),
    );

    if (picked != null) {
      setState(() {
        final hourStr = picked.hour.toString().padLeft(2, '0');
        final minStr = picked.minute.toString().padLeft(2, '0');
        _startTime = '$hourStr:$minStr';
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFieldId == null || _selectedTargetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field and Target selection are required.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final duration = int.parse(_durationController.text);
    final state = context.read<AppState>();
    bool ok;

    if (widget.schedule == null) {
      ok = await state.createSchedule(
        name: name,
        fieldId: _selectedFieldId!,
        targetType: _targetType,
        targetId: _selectedTargetId!,
        startTime: _startTime,
        durationMinutes: duration,
        repeatType: _repeatType,
        repeatDays: _repeatDays,
      );
    } else {
      ok = await state.updateSchedule(
        scheduleId: widget.schedule!.id,
        name: name,
        startTime: _startTime,
        durationMinutes: duration,
        repeatType: _repeatType,
        repeatDays: _repeatDays,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.schedule == null ? 'Schedule created successfully' : 'Schedule updated successfully'),
          backgroundColor: const Color(0xFF2D7A3A),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.schedule != null;
    final state = context.watch<AppState>();

    // Target Selection options based on Field and TargetType
    List<DropdownMenuItem<String>> targetItems = [];
    if (_selectedFieldId != null && state.fields.isNotEmpty) {
      final field = state.fields.firstWhere((f) => f.id == _selectedFieldId, orElse: () => state.fields[0]);
      if (_targetType == 'zone') {
        targetItems = field.zones.map((z) => DropdownMenuItem(value: z.id, child: Text(z.name))).toList();
      } else {
        // Collect all valves across zones
        final List<Valve> valves = [];
        for (var zone in field.zones) {
          valves.addAll(zone.valves);
        }
        targetItems = valves.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))).toList();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Schedule' : 'Create Schedule'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Schedule Name',
                hint: 'e.g. Sugar Block Drip A',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Schedule name is required' : null,
              ),
              const SizedBox(height: 16),

              if (!isEdit) ...[
                const Text('Select Field', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedFieldId,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  items: state.fields.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedFieldId = val;
                      _selectedTargetId = null; // Reset target selection
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text('Target Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Zone', style: TextStyle(fontSize: 14)),
                        value: 'zone',
                        groupValue: _targetType,
                        activeColor: const Color(0xFF2D7A3A),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _targetType = val!;
                            _selectedTargetId = null;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Valve', style: TextStyle(fontSize: 14)),
                        value: 'valve',
                        groupValue: _targetType,
                        activeColor: const Color(0xFF2D7A3A),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _targetType = val!;
                            _selectedTargetId = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Select Target', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTargetId,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  items: targetItems,
                  onChanged: (val) => setState(() => _selectedTargetId = val),
                  validator: (v) => v == null ? 'Target selection is required' : null,
                ),
                const SizedBox(height: 16),
              ],

              // Duration
              AppTextField(
                label: 'Duration (Minutes)',
                hint: 'e.g. 45',
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Duration is required';
                  final num = int.tryParse(v);
                  if (num == null || num <= 0) return 'Duration must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Time selector
              const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _startTime,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                      ),
                      const Icon(Icons.access_time_rounded, color: Color(0xFF2D7A3A)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Repeat Selection
              const Text('Repeat Setting', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _repeatType,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                items: const [
                  DropdownMenuItem(value: 'once', child: Text('Once')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'customDays', child: Text('Custom Days')),
                ],
                onChanged: (val) => setState(() => _repeatType = val!),
              ),
              const SizedBox(height: 32),

              AppLoadingButton(
                label: isEdit ? 'Update Schedule' : 'Create Schedule',
                isLoading: _isLoading,
                onPressed: _saveSchedule,
                color: const Color(0xFF2D7A3A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
