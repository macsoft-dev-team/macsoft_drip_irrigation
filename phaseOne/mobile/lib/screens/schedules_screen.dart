import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/irrigation_schedule.dart';
import '../models/field.dart';
import '../models/zone.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await state.loadSchedules();
        },
        child: state.schedules.isEmpty
            ? const Center(child: Text("No schedules configured yet."))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.schedules.length,
                itemBuilder: (context, idx) {
                  final s = state.schedules[idx];
                  final bool isActive = s.status == 'active';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isActive ? const Color(0xFF1E4D2B) : Colors.grey).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.alarm,
                          color: isActive ? const Color(0xFF1E4D2B) : Colors.grey,
                        ),
                      ),
                      title: Text(
                        s.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black87 : Colors.black45,
                        ),
                      ),
                      subtitle: Text(
                        "Farm: ${state.fields.firstWhere((f) => f.id == s.fieldId, orElse: () => const Field(id: '', farmerId: '', name: 'Unknown Farm', status: '')).name}\nStart Time: ${s.startTime} • Duration: ${s.durationMinutes} min\nRepeat: ${s.repeatDays.join(', ')}",
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            activeColor: const Color(0xFF00E676),
                            onChanged: (val) async {
                              await state.toggleScheduleStatus(s.id);
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => ScheduleFormScreen(schedule: s),
                                  ),
                                );
                              } else if (action == 'delete') {
                                _confirmDelete(context, state, s.id);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(value: 'edit', child: Text("Edit")),
                              const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E4D2B),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => const ScheduleFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, String id) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Schedule"),
        content: const Text("Are you sure you want to delete this irrigation schedule?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await state.deleteSchedule(id);
              if (context.mounted) Navigator.pop(c);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ScheduleFormScreen extends StatefulWidget {
  final IrrigationSchedule? schedule;
  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _fieldId;
  late String _zoneId;
  late String _startTime;
  late int _durationMinutes;
  late List<String> _repeatDays;
  bool _isLoading = false;

  final List<String> _weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    
    if (widget.schedule != null) {
      final s = widget.schedule!;
      _name = s.name;
      _fieldId = s.fieldId;
      _zoneId = s.targetId;
      _startTime = s.startTime;
      _durationMinutes = s.durationMinutes;
      _repeatDays = List.from(s.repeatDays);
    } else {
      _name = "New Drip Schedule";
      _fieldId = state.fields.isNotEmpty ? state.fields.first.id : "";
      final activeField = state.fields.isNotEmpty ? state.fields.first : null;
      _zoneId = (activeField != null && activeField.zones.isNotEmpty) ? activeField.zones.first.id : "";
      _startTime = "06:00";
      _durationMinutes = 15;
      _repeatDays = ["monday", "wednesday", "friday"];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    if (state.fields.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Create Schedule")),
        body: const Center(child: Text("Configure fields and zones before creating schedules.")),
      );
    }

    final activeField = state.fields.firstWhere((element) => element.id == _fieldId, orElse: () => state.fields.first);

    return Scaffold(
      appBar: AppBar(title: Text(widget.schedule == null ? "Create Schedule" : "Edit Schedule")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: "Schedule Name"),
                validator: (v) => v!.isEmpty ? "Enter schedule name" : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 20),

              // Field Selection
              DropdownButtonFormField<String>(
                value: _fieldId.isEmpty ? null : _fieldId,
                decoration: const InputDecoration(labelText: "Farm Field"),
                items: state.fields.map((f) {
                  return DropdownMenuItem<String>(value: f.id, child: Text(f.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _fieldId = val;
                      final f = state.fields.firstWhere((element) => element.id == val);
                      _zoneId = f.zones.isNotEmpty ? f.zones.first.id : "";
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Zone Selection
              DropdownButtonFormField<String>(
                value: _zoneId.isEmpty ? null : _zoneId,
                decoration: const InputDecoration(labelText: "Zone Target"),
                items: activeField.zones.map((z) {
                  return DropdownMenuItem<String>(value: z.id, child: Text(z.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _zoneId = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Start Time
              ListTile(
                title: const Text("Start Time", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_startTime, style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final initialTimeParts = _startTime.split(':');
                  int initialHour = 6;
                  int initialMin = 0;
                  if (initialTimeParts.length == 2) {
                    initialHour = int.tryParse(initialTimeParts[0]) ?? 6;
                    initialMin = int.tryParse(initialTimeParts[1]) ?? 0;
                  }

                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
                  );
                  if (time != null) {
                    final String formattedTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    setState(() {
                      _startTime = formattedTime;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Duration
              TextFormField(
                initialValue: _durationMinutes.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Duration (Minutes)"),
                validator: (v) => int.tryParse(v!) == null ? "Enter valid number" : null,
                onSaved: (v) => _durationMinutes = int.parse(v!),
              ),
              const SizedBox(height: 24),

              // Repeat Days
              const Text("Repeat Days", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _weekdays.map((day) {
                  bool isSel = _repeatDays.contains(day);
                  return FilterChip(
                    label: Text(day[0].toUpperCase() + day.substring(1, 3)),
                    selected: isSel,
                    selectedColor: const Color(0xFF1E4D2B),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _repeatDays.add(day);
                        } else {
                          _repeatDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          setState(() => _isLoading = true);

                          bool ok;
                          if (widget.schedule == null) {
                            ok = await state.createSchedule(
                              name: _name,
                              fieldId: _fieldId,
                              targetType: 'zone',
                              targetId: _zoneId,
                              startTime: _startTime,
                              durationMinutes: _durationMinutes,
                              repeatType: 'customDays',
                              repeatDays: _repeatDays,
                            );
                          } else {
                            ok = await state.updateSchedule(
                              scheduleId: widget.schedule!.id,
                              name: _name,
                              startTime: _startTime,
                              durationMinutes: _durationMinutes,
                              repeatType: 'customDays',
                              repeatDays: _repeatDays,
                            );
                          }

                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          if (ok) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: const Text("SAVE SCHEDULE"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
