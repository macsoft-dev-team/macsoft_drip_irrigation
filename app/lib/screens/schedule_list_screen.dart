import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/irrigation_schedule.dart';
import '../models/field.dart';
import '../models/valve.dart';
import '../models/zone.dart';
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

                String targetDisplay = '';
                if (sched.scheduleType == 'timerBased' && sched.zoneIds != null && sched.zoneIds!.isNotEmpty) {
                  final zoneNames = sched.zoneIds!.map((zId) {
                    final zoneIdx = field.zones.indexWhere((z) => z.id == zId);
                    return zoneIdx != -1 ? field.zones[zoneIdx].name : 'Zone $zId';
                  }).join(' → ');
                  targetDisplay = 'Sequence: $zoneNames';
                } else {
                  targetDisplay = 'Target: ${sched.targetType.toUpperCase()} · ${sched.targetName ?? sched.targetId}';
                }

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
                        const SizedBox(height: 2),
                        Text(
                          targetDisplay,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
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
                                  sched.scheduleType == 'timerBased'
                                      ? '${sched.startTime} (${sched.durationMinutes} mins/zone)'
                                      : '${sched.startTime} (${sched.durationMinutes} mins)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sched.scheduleType == 'timerBased'
                                        ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                                        : const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    sched.scheduleType == 'timerBased' ? 'SEQUENTIAL' : 'PARALLEL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: sched.scheduleType == 'timerBased'
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF2D7A3A),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                StatusChip(status: sched.repeatType),
                              ],
                            ),
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
  final String? initialFieldId;
  final String? initialTargetType;
  final String? initialTargetId;

  const ScheduleFormScreen({
    super.key,
    this.schedule,
    this.initialFieldId,
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
  String _scheduleType = 'timeBased'; // timeBased, timerBased
  String _targetType = 'zone'; // zone, valve
  String? _selectedTargetId;
  List<String> _selectedZoneIds = []; // Ordering list for sequential run
  String _startTime = '06:00';
  String _repeatType = 'daily'; // once, daily, weekly, customDays
  List<String> _repeatDays = [];

  bool _isLoading = false;

  final List<Map<String, String>> _weekdays = [
    {'label': 'M', 'value': 'monday'},
    {'label': 'T', 'value': 'tuesday'},
    {'label': 'W', 'value': 'wednesday'},
    {'label': 'T', 'value': 'thursday'},
    {'label': 'F', 'value': 'friday'},
    {'label': 'S', 'value': 'saturday'},
    {'label': 'S', 'value': 'sunday'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schedule?.name ?? '');
    _durationController = TextEditingController(
      text: widget.schedule?.durationMinutes.toString() ?? '30',
    );

    if (widget.schedule != null) {
      _selectedFieldId = widget.schedule!.fieldId;
      _scheduleType = widget.schedule!.scheduleType;
      _targetType = widget.schedule!.targetType;
      _selectedTargetId = widget.schedule!.targetId;
      _selectedZoneIds = List<String>.from(widget.schedule!.zoneIds ?? []);
      _startTime = widget.schedule!.startTime;
      _repeatType = widget.schedule!.repeatType;
      _repeatDays = List<String>.from(widget.schedule!.repeatDays);
    } else {
      _scheduleType = 'timeBased';
      _targetType = widget.initialTargetType ?? 'zone';
      _selectedTargetId = widget.initialTargetId;
      
      if (widget.initialFieldId != null) {
        _selectedFieldId = widget.initialFieldId;
      } else {
        // Auto-select first field if available
        final state = context.read<AppState>();
        if (state.fields.isNotEmpty) {
          _selectedFieldId = state.fields[0].id;
        }
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

    if (_selectedFieldId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field selection is required.')),
      );
      return;
    }

    if (_scheduleType == 'timerBased') {
      if (_selectedZoneIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one zone must be selected for sequential run.')),
        );
        return;
      }
      _targetType = 'zone';
      _selectedTargetId = _selectedZoneIds.first;
    } else {
      if (_selectedTargetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target selection is required.')),
        );
        return;
      }
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
        scheduleType: _scheduleType,
        zoneIds: _scheduleType == 'timerBased' ? _selectedZoneIds : null,
      );
    } else {
      ok = await state.updateSchedule(
        scheduleId: widget.schedule!.id,
        name: name,
        startTime: _startTime,
        durationMinutes: duration,
        repeatType: _repeatType,
        repeatDays: _repeatDays,
        scheduleType: _scheduleType,
        zoneIds: _scheduleType == 'timerBased' ? _selectedZoneIds : null,
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

  Zone _dummyZone(String id) {
    return Zone(id: id, fieldId: '', name: 'Zone $id', status: 'unknown');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.schedule != null;
    final state = context.watch<AppState>();

    // Target Selection options based on Field and TargetType
    List<DropdownMenuItem<String>> targetItems = [];
    List<Zone> allZones = [];
    if (_selectedFieldId != null && state.fields.isNotEmpty) {
      final field = state.fields.firstWhere((f) => f.id == _selectedFieldId, orElse: () => state.fields[0]);
      allZones = field.zones;
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
        child: ListView(
          padding: const EdgeInsets.all(20.0),
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
                      _selectedZoneIds = []; // Reset sequential selection
                    });
                  },
                ),
                const SizedBox(height: 16),

                const Text('Schedule Configuration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Time-based (Parallel)'),
                      selected: _scheduleType == 'timeBased',
                      selectedColor: const Color(0xFF2D7A3A).withValues(alpha: 0.15),
                      checkmarkColor: const Color(0xFF2D7A3A),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      labelPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        color: _scheduleType == 'timeBased' ? const Color(0xFF2D7A3A) : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _scheduleType = 'timeBased';
                            _selectedTargetId = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Timer-based (Sequence)'),
                      selected: _scheduleType == 'timerBased',
                      selectedColor: const Color(0xFF2D7A3A).withValues(alpha: 0.15),
                      checkmarkColor: const Color(0xFF2D7A3A),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      labelPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        color: _scheduleType == 'timerBased' ? const Color(0xFF2D7A3A) : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _scheduleType = 'timerBased';
                            _targetType = 'zone';
                            _selectedTargetId = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Render standard target options for timeBased
                if (_scheduleType == 'timeBased') ...[
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
              ],

              // Show sequential zone checklist & ReorderableListView in both edit and create modes for timerBased
              if (_scheduleType == 'timerBased') ...[
                const Text('Select Zones to Run in Sequence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
                const SizedBox(height: 6),
                if (allZones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No zones found for the selected field.', style: TextStyle(color: Colors.red, fontSize: 13)),
                  )
                else
                  ...allZones.map((zone) {
                    final isChecked = _selectedZoneIds.contains(zone.id);
                    return CheckboxListTile(
                      title: Text(zone.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: isChecked,
                      activeColor: const Color(0xFF2D7A3A),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            if (!_selectedZoneIds.contains(zone.id)) {
                              _selectedZoneIds.add(zone.id);
                            }
                          } else {
                            _selectedZoneIds.remove(zone.id);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                const SizedBox(height: 16),

                if (_selectedZoneIds.isNotEmpty) ...[
                  const Text('Sequence Order (Drag to Reorder)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _selectedZoneIds.removeAt(oldIndex);
                          _selectedZoneIds.insert(newIndex, item);
                        });
                      },
                      children: List.generate(_selectedZoneIds.length, (i) {
                        final zId = _selectedZoneIds[i];
                        final zone = allZones.firstWhere((z) => z.id == zId, orElse: () => _dummyZone(zId));
                        return ListTile(
                          key: ValueKey(zId),
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF2D7A3A),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            zone.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],

              // Duration
              AppTextField(
                label: _scheduleType == 'timerBased' ? 'Duration per Zone (Minutes)' : 'Duration (Minutes)',
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
                onChanged: (val) => setState(() {
                  _repeatType = val!;
                  if (_repeatType == 'once' || _repeatType == 'daily') {
                    _repeatDays = [];
                  }
                }),
              ),

              // Custom days selector
              if (_repeatType == 'customDays' || _repeatType == 'weekly') ...[
                const SizedBox(height: 16),
                const Text('Select Days of Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekdays.map((day) {
                    final isSelected = _repeatDays.contains(day['value']);
                    return FilterChip(
                      label: Text(day['label']!),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2D7A3A).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF2D7A3A),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      labelPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF2D7A3A) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (!_repeatDays.contains(day['value']!)) {
                              _repeatDays.add(day['value']!);
                            }
                          } else {
                            _repeatDays.remove(day['value']!);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
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
      );
  }
}
