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
                if (sched.scheduleType == 'rtcBased' && sched.sequenceData != null && sched.sequenceData!.isNotEmpty) {
                  final List<String> zoneParts = [];
                  for (var zoneItem in sched.sequenceData!) {
                    final zoneName = zoneItem['zoneName'] ?? 'Zone';
                    final valves = zoneItem['valves'] as List<dynamic>? ?? [];
                    final activeValves = valves.where((v) => v['checked'] != false).toList();
                    if (activeValves.isNotEmpty) {
                      final valveParts = activeValves.map((v) {
                        final name = v['valveName'] ?? 'Valve';
                        final start = v['startTime'] ?? '';
                        final end = v['endTime'] ?? '';
                        return '$name ($start-$end)';
                      }).join(', ');
                      zoneParts.add('$zoneName: [$valveParts]');
                    }
                  }
                  targetDisplay = 'RTC Sequence: ${zoneParts.join(' → ')}';
                } else if (sched.scheduleType == 'timerBased' && sched.sequenceData != null && sched.sequenceData!.isNotEmpty) {
                  final calculated = calculateTimerSequenceTimes(sched.startTime, sched.sequenceData!);
                  final items = calculated.map((item) {
                    final name = item['name'] ?? 'Item ${item['id']}';
                    final start = item['startTime'] ?? '';
                    final end = item['endTime'] ?? '';
                    final dur = item['duration'] ?? 0;
                    return '$name ($start-$end, ${dur}m)';
                  }).join(' → ');
                  targetDisplay = 'Timer Sequence: $items';
                } else if (sched.scheduleType == 'timerBased' && sched.zoneIds != null && sched.zoneIds!.isNotEmpty) {
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
                                      ? '${sched.startTime} (Sequential sequence)'
                                      : sched.scheduleType == 'rtcBased'
                                          ? 'RTC: Start ${sched.startTime} (${sched.durationMinutes} mins total)'
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
                                        : sched.scheduleType == 'rtcBased'
                                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                                            : const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    sched.scheduleType == 'timerBased'
                                        ? 'TIMER SEQ'
                                        : sched.scheduleType == 'rtcBased'
                                            ? 'RTC SEQ'
                                            : 'PARALLEL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: sched.scheduleType == 'timerBased'
                                          ? const Color(0xFFD97706)
                                          : sched.scheduleType == 'rtcBased'
                                              ? const Color(0xFF7C3AED)
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
  String _scheduleType = 'timeBased'; // timeBased, timerBased, rtcBased
  String _targetType = 'zone'; // zone, valve
  String? _selectedTargetId;
  String _startTime = '06:00';
  String _repeatType = 'daily'; // once, daily, weekly, customDays
  List<String> _repeatDays = [];

  // Sequential structures
  List<Map<String, dynamic>> _rtcZones = []; // List of {zoneId, zoneName, valves: [{valveId, valveName, startTime, endTime, checked}]}
  List<Map<String, dynamic>> _timerSequence = []; // List of {type: 'zone'/'valve', id, name, duration}

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
      _startTime = widget.schedule!.startTime;
      _repeatType = widget.schedule!.repeatType;
      _repeatDays = List<String>.from(widget.schedule!.repeatDays);

      if (_scheduleType == 'rtcBased') {
        _rtcZones = (widget.schedule!.sequenceData as List<dynamic>?)
                ?.map((z) => {
                      'zoneId': z['zoneId']?.toString(),
                      'zoneName': z['zoneName']?.toString(),
                      'valves': (z['valves'] as List<dynamic>?)
                              ?.map((v) => {
                                    'valveId': v['valveId']?.toString(),
                                    'valveName': v['valveName']?.toString(),
                                    'startTime': v['startTime']?.toString() ?? '06:00',
                                    'endTime': v['endTime']?.toString() ?? '06:15',
                                    'checked': v['checked'] ?? true,
                                  })
                              .toList() ??
                          [],
                    })
                .toList() ??
            [];
      } else if (_scheduleType == 'timerBased') {
        _timerSequence = (widget.schedule!.sequenceData as List<dynamic>?)
                ?.map((item) => Map<String, dynamic>.from(item as Map))
                .toList() ?? [];
      }
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

  void _toggleRtcZoneSelection(Zone zone) {
    final exists = _rtcZones.any((z) => z['zoneId'] == zone.id);
    if (exists) {
      setState(() {
        _rtcZones.removeWhere((z) => z['zoneId'] == zone.id);
      });
    } else {
      int lastHour = 6;
      int lastMinute = 0;
      if (_rtcZones.isNotEmpty) {
        final lastZone = _rtcZones.last;
        final lastValves = lastZone['valves'] as List<dynamic>? ?? [];
        if (lastValves.isNotEmpty) {
          final lastTime = lastValves.last['endTime'] as String? ?? '06:00';
          final parts = lastTime.split(':');
          if (parts.length == 2) {
            lastHour = int.tryParse(parts[0]) ?? 6;
            lastMinute = int.tryParse(parts[1]) ?? 0;
          }
        }
      }
      
      final valvesList = zone.valves;
      int currentHour = lastHour;
      int currentMinute = lastMinute;
      
      final defaultValves = List.generate(valvesList.length, (i) {
        final v = valvesList[i];
        
        final startH = currentHour.toString().padLeft(2, '0');
        final startM = currentMinute.toString().padLeft(2, '0');
        
        currentMinute += 15;
        if (currentMinute >= 60) {
          currentHour += 1;
          currentMinute -= 60;
        }
        
        final endH = currentHour.toString().padLeft(2, '0');
        final endM = currentMinute.toString().padLeft(2, '0');
        
        return {
          'valveId': v.id,
          'valveName': v.name,
          'startTime': '$startH:$startM',
          'endTime': '$endH:$endM',
          'checked': true,
        };
      });

      setState(() {
        _rtcZones.add({
          'zoneId': zone.id,
          'zoneName': zone.name,
          'valves': defaultValves,
        });
      });
    }
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

  Future<void> _selectValveTime(BuildContext context, Map<String, dynamic> valveItem, bool isStart) async {
    final key = isStart ? 'startTime' : 'endTime';
    final curTime = valveItem[key] as String? ?? '06:00';
    final curParts = curTime.split(':');
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
        valveItem[key] = '$hourStr:$minStr';
      });
    }
  }

  int _calculateRtcTotalDuration() {
    if (_rtcZones.isEmpty) return 30;
    try {
      int minMinutes = 24 * 60;
      int maxMinutes = 0;
      for (var z in _rtcZones) {
        final valves = z['valves'] as List<dynamic>? ?? [];
        for (var v in valves) {
          if (v['checked'] == false) continue;
          final startParts = v['startTime'].split(':');
          final endParts = v['endTime'].split(':');
          final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          if (startMin < minMinutes) minMinutes = startMin;
          if (endMin > maxMinutes) maxMinutes = endMin;
        }
      }
      if (maxMinutes > minMinutes) {
        return maxMinutes - minMinutes;
      }
    } catch (_) {}
    return 30;
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFieldId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field selection is required.')),
      );
      return;
    }

    List<dynamic>? seqData;
    int duration = 30;

    if (_scheduleType == 'rtcBased') {
      if (_rtcZones.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one zone must be selected for RTC scheduling.')),
        );
        return;
      }
      bool hasActiveValves = false;
      for (var z in _rtcZones) {
        final valves = z['valves'] as List<dynamic>? ?? [];
        if (valves.any((v) => v['checked'] != false)) {
          hasActiveValves = true;
          break;
        }
      }
      if (!hasActiveValves) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one valve must be selected to schedule.')),
        );
        return;
      }
      _targetType = 'zone';
      _selectedTargetId = _rtcZones.first['zoneId'];
      seqData = _rtcZones;
      duration = _calculateRtcTotalDuration();
      
      try {
        String? firstStart;
        for (var z in _rtcZones) {
          final valves = z['valves'] as List<dynamic>? ?? [];
          final active = valves.where((v) => v['checked'] != false).toList();
          if (active.isNotEmpty) {
            firstStart = active.first['startTime'];
            break;
          }
        }
        if (firstStart != null) {
          _startTime = firstStart;
        }
      } catch (_) {}
    } else if (_scheduleType == 'timerBased') {
      if (_timerSequence.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one zone or valve must be added to the sequence.')),
        );
        return;
      }
      _targetType = _timerSequence.first['type'] ?? 'zone';
      _selectedTargetId = _timerSequence.first['id'];
      seqData = _timerSequence;
      duration = _timerSequence.fold<int>(0, (sum, item) => sum + (item['duration'] as int? ?? 15));
    } else {
      if (_selectedTargetId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target selection is required.')),
        );
        return;
      }
      duration = int.parse(_durationController.text);
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
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
        sequenceData: seqData,
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
        sequenceData: seqData,
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

    List<DropdownMenuItem<String>> targetItems = [];
    List<Zone> allZones = [];
    if (_selectedFieldId != null && state.fields.isNotEmpty) {
      final field = state.fields.firstWhere((f) => f.id == _selectedFieldId, orElse: () => state.fields[0]);
      allZones = field.zones;
      if (_targetType == 'zone') {
        targetItems = field.zones.map((z) => DropdownMenuItem(value: z.id, child: Text(z.name))).toList();
      } else {
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
                    _selectedTargetId = null;
                    _rtcZones = [];
                    _timerSequence = [];
                  });
                },
              ),
              const SizedBox(height: 16),

              const Text('Schedule Configuration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Parallel (Time)'),
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
                    label: const Text('RTC (Valves)'),
                    selected: _scheduleType == 'rtcBased',
                    selectedColor: const Color(0xFF2D7A3A).withValues(alpha: 0.15),
                    checkmarkColor: const Color(0xFF2D7A3A),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    labelPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      color: _scheduleType == 'rtcBased' ? const Color(0xFF2D7A3A) : const Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _scheduleType = 'rtcBased';
                          _rtcZones = [];
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Timer (Sequence)'),
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
                          _timerSequence = [];
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

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

            if (_scheduleType == 'rtcBased') ...[
              const Text('Select Zones to Schedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
              const SizedBox(height: 8),
              if (allZones.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No zones found for this field.', style: TextStyle(color: Colors.red, fontSize: 13)),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allZones.map((z) {
                    final isSelected = _rtcZones.any((item) => item['zoneId'] == z.id);
                    return FilterChip(
                      label: Text(z.name),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2D7A3A).withValues(alpha: 0.15),
                      checkmarkColor: const Color(0xFF2D7A3A),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF2D7A3A) : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      onSelected: (selected) {
                        _toggleRtcZoneSelection(z);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              if (_rtcZones.isNotEmpty) ...[
                const Text('Zone & Valve Sequences (Drag up/down to reorder zones/valves)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
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
                        final item = _rtcZones.removeAt(oldIndex);
                        _rtcZones.insert(newIndex, item);
                      });
                    },
                    children: List.generate(_rtcZones.length, (zIdx) {
                      final zItem = _rtcZones[zIdx];
                      final zoneName = zItem['zoneName'] ?? '';
                      final valves = zItem['valves'] as List<dynamic>? ?? [];

                      return Card(
                        key: ValueKey(zItem['zoneId']),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                              title: Row(
                                children: [
                                  const Icon(Icons.grid_view, size: 16, color: Color(0xFF8B5CF6)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      zoneName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2A1F)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, thickness: 0.5),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ReorderableListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                onReorder: (oldValIdx, newValIdx) {
                                  setState(() {
                                    if (oldValIdx < newValIdx) {
                                      newValIdx -= 1;
                                    }
                                    final valList = List<Map<String, dynamic>>.from(zItem['valves']);
                                    final moved = valList.removeAt(oldValIdx);
                                    valList.insert(newValIdx, moved);
                                    zItem['valves'] = valList;
                                  });
                                },
                                children: List.generate(valves.length, (vIdx) {
                                  final vItem = valves[vIdx];
                                  final isValveChecked = vItem['checked'] != false;
                                  return Container(
                                    key: ValueKey('${zItem['zoneId']}_${vItem['valveId']}'),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isValveChecked ? Colors.white : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isValveChecked ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
                                        style: isValveChecked ? BorderStyle.solid : BorderStyle.none,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.drag_handle_rounded, color: Colors.grey, size: 16),
                                            Checkbox(
                                              value: isValveChecked,
                                              activeColor: const Color(0xFF8B5CF6),
                                              onChanged: (val) {
                                                setState(() {
                                                  vItem['checked'] = val ?? true;
                                                });
                                              },
                                            ),
                                            Expanded(
                                              child: Text(
                                                vItem['valveName'] ?? 'Valve',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isValveChecked ? const Color(0xFF1E2A1F) : Colors.grey,
                                                  decoration: isValveChecked ? null : TextDecoration.lineThrough,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isValveChecked) ...[
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 32.0),
                                            child: Row(
                                              children: [
                                                const Text('Start: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                InkWell(
                                                  onTap: () => _selectValveTime(context, vItem, true),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      vItem['startTime'] ?? '06:00',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                const Text('End: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                InkWell(
                                                  onTap: () => _selectValveTime(context, vItem, false),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      vItem['endTime'] ?? '06:15',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A)),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],

            if (_scheduleType == 'timerBased') ...[
              const Text('Add Zones / Valves to Run in Sequence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
              const SizedBox(height: 8),
              if (allZones.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No zones or valves found.', style: TextStyle(color: Colors.red, fontSize: 13)),
                )
              else ...[
                const Text('Available Zones:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: allZones
                      .where((z) => !_timerSequence.any((item) => item['type'] == 'zone' && item['id'] == z.id))
                      .map((z) {
                    return ActionChip(
                      avatar: const Icon(Icons.add, size: 14, color: Colors.white),
                      backgroundColor: const Color(0xFF2D7A3A),
                      label: Text(z.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      onPressed: () {
                        setState(() {
                          _timerSequence.add({
                            'type': 'zone',
                            'id': z.id,
                            'name': z.name,
                            'duration': 15,
                          });
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text('Available Valves:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: allZones
                      .expand((z) => z.valves)
                      .where((v) => !_timerSequence.any((item) => item['type'] == 'valve' && item['id'] == v.id))
                      .map((v) {
                    return ActionChip(
                      avatar: const Icon(Icons.add, size: 14, color: Colors.white),
                      backgroundColor: Colors.teal,
                      label: Text(v.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      onPressed: () {
                        setState(() {
                          _timerSequence.add({
                            'type': 'valve',
                            'id': v.id,
                            'name': v.name,
                            'duration': 15,
                          });
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              if (_timerSequence.isNotEmpty) ...[
                const Text('Sequence Items (Drag up/down to reorder sequence)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
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
                        final item = _timerSequence.removeAt(oldIndex);
                        _timerSequence.insert(newIndex, item);
                      });
                    },
                    children: () {
                      final calculated = calculateTimerSequenceTimes(_startTime, _timerSequence);
                      return List.generate(calculated.length, (i) {
                        final item = calculated[i];
                        final isZone = item['type'] == 'zone';
                        final start = item['startTime'] ?? '';
                        final end = item['endTime'] ?? '';
                        return Card(
                          key: ValueKey('${item['type']}_${item['id']}_$i'),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                            title: Row(
                              children: [
                                Icon(isZone ? Icons.grid_view : Icons.radio_button_checked, size: 16, color: isZone ? const Color(0xFF2D7A3A) : Colors.teal),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('Run Duration: ', style: TextStyle(fontSize: 11)),
                                    SizedBox(
                                      width: 45,
                                      child: TextFormField(
                                        initialValue: item['duration'].toString(),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _timerSequence[i]['duration'] = int.tryParse(val) ?? 15;
                                          });
                                        },
                                      ),
                                    ),
                                    const Text(' mins', style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Calculated Run: $start - $end',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _timerSequence.removeAt(i);
                                });
                              },
                            ),
                          ),
                        );
                      });
                    }(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],

            if (_scheduleType == 'timeBased') ...[
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
            ],

            if (_scheduleType != 'rtcBased') ...[
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
            ],

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

List<Map<String, dynamic>> calculateTimerSequenceTimes(String startTimeStr, List<dynamic> sequence) {
  if (sequence.isEmpty) return [];
  
  int currentHour = 8;
  int currentMinute = 0;
  
  try {
    final cleanTime = startTimeStr.toUpperCase().replaceAll(RegExp(r'[AP]M'), '').trim();
    final parts = cleanTime.split(':');
    if (parts.length >= 2) {
      currentHour = int.tryParse(parts[0]) ?? 8;
      currentMinute = int.tryParse(parts[1]) ?? 0;
    }
    
    if (startTimeStr.toUpperCase().contains('PM') && currentHour < 12) {
      currentHour += 12;
    } else if (startTimeStr.toUpperCase().contains('AM') && currentHour == 12) {
      currentHour = 0;
    }
  } catch (_) {
    currentHour = 8;
    currentMinute = 0;
  }

  final List<Map<String, dynamic>> result = [];
  for (var item in sequence) {
    final mapItem = Map<String, dynamic>.from(item as Map);
    
    final startH = currentHour.toString().padLeft(2, '0');
    final startM = currentMinute.toString().padLeft(2, '0');
    
    final duration = mapItem['duration'] as int? ?? 15;
    currentMinute += duration;
    while (currentMinute >= 60) {
      currentHour = (currentHour + 1) % 24;
      currentMinute -= 60;
    }
    
    final endH = currentHour.toString().padLeft(2, '0');
    final endM = currentMinute.toString().padLeft(2, '0');
    
    mapItem['startTime'] = '$startH:$startM';
    mapItem['endTime'] = '$endH:$endM';
    result.add(mapItem);
  }
  
  return result;
}
