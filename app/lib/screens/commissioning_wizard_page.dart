import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/field.dart';
import '../models/slave_board.dart';
import '../models/valve.dart';
import '../models/zone.dart';
import '../services/app_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_text_field.dart';

class CommissioningWizardPage extends StatefulWidget {
  final Field field;
  const CommissioningWizardPage({super.key, required this.field});

  @override
  State<CommissioningWizardPage> createState() => _CommissioningWizardPageState();
}

class _CommissioningWizardPageState extends State<CommissioningWizardPage> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Register Master
  final _deviceUidCtrl = TextEditingController();
  final _imeiCtrl = TextEditingController();
  final _simCtrl = TextEditingController();
  String _connectionType = 'gsm4g';

  // Step 2: Add Slave Boards
  final _slaveNameCtrl = TextEditingController();
  final _slaveUidCtrl = TextEditingController();
  final _slaveAddrCtrl = TextEditingController(text: '1');

  // Step 4: Discover & Test Outputs
  SlaveBoard? _selectedTestBoard;
  int _selectedCoil = 0;
  bool _isTestingCoil = false;

  // Step 5: Name Valves
  final Map<String, TextEditingController> _valveNameControllers = {};
  final List<Map<String, dynamic>> _newValves = []; // stores temporary configured valve details during wizard

  // Step 6: Create Zones
  final _zoneNameCtrl = TextEditingController();
  final _zoneDescCtrl = TextEditingController();
  final Map<String, bool> _selectedValvesForZone = {};

  @override
  void initState() {
    super.initState();
    if (widget.field.masterController != null) {
      _deviceUidCtrl.text = widget.field.masterController!.deviceUid;
      _imeiCtrl.text = widget.field.masterController!.imei ?? '';
      _simCtrl.text = widget.field.masterController!.simNumber ?? '';
      _connectionType = widget.field.masterController!.connectionType;
      // Skip master registration if master already exists
      _currentStep = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSlaves();
      });
    }
  }

  Future<void> _loadSlaves() async {
    final state = context.read<AppState>();
    if (widget.field.masterController != null) {
      await state.loadSlaveBoards(widget.field.masterController!.id);
      if (state.slaveBoards.isNotEmpty) {
        setState(() {
          _selectedTestBoard = state.slaveBoards.first;
        });
      }
    }
  }

  @override
  void dispose() {
    _deviceUidCtrl.dispose();
    _imeiCtrl.dispose();
    _simCtrl.dispose();
    _slaveNameCtrl.dispose();
    _slaveUidCtrl.dispose();
    _slaveAddrCtrl.dispose();
    _zoneNameCtrl.dispose();
    _zoneDescCtrl.dispose();
    for (var ctrl in _valveNameControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _nextStep() async {
    final state = context.read<AppState>();
    setState(() => _isLoading = true);

    try {
      if (_currentStep == 0) {
        // Step 1: Register Master
        if (_deviceUidCtrl.text.trim().isEmpty) {
          throw Exception('Device UID is required.');
        }
        final ok = await state.createMasterController(
          widget.field.id,
          deviceUid: _deviceUidCtrl.text.trim(),
          imei: _imeiCtrl.text.trim().isEmpty ? null : _imeiCtrl.text.trim(),
          simNumber: _simCtrl.text.trim().isEmpty ? null : _simCtrl.text.trim(),
          connectionType: _connectionType,
        );
        if (!ok) throw Exception('Failed to register master controller.');
        await state.loadFields();
        await _loadSlaves();
        setState(() => _currentStep = 1);
      } else if (_currentStep == 1) {
        // Step 2: Add Slave Boards
        if (state.slaveBoards.isEmpty) {
          throw Exception('Please add at least one Slave Board.');
        }
        setState(() => _currentStep = 2);
      } else if (_currentStep == 2) {
        // Step 3: Set Modbus Address
        setState(() => _currentStep = 3);
      } else if (_currentStep == 3) {
        // Step 4: Discover & Test Outputs
        setState(() => _currentStep = 4);
      } else if (_currentStep == 4) {
        // Step 5: Name Valves & Save to database
        for (var vDetails in _newValves) {
          final ctrl = _valveNameControllers[vDetails['key']];
          final name = ctrl?.text.trim() ?? '';
          if (name.isEmpty) throw Exception('Please name all discovered valves.');
          
          await state.createValveDirect(
            slaveBoardId: vDetails['slaveBoardId'],
            name: name,
            deviceUid: vDetails['deviceUid'],
            coilAddress: vDetails['coilAddress'],
          );
        }
        await state.loadFields();
        // Initialize step 6 valve selections
        _selectedValvesForZone.clear();
        setState(() => _currentStep = 5);
      } else if (_currentStep == 5) {
        // Step 6: Create Zone & Assign Valves
        if (_zoneNameCtrl.text.trim().isEmpty) {
          throw Exception('Zone Name is required.');
        }
        final ok = await state.createZone(
          fieldId: widget.field.id,
          name: _zoneNameCtrl.text.trim(),
          description: _zoneDescCtrl.text.trim(),
        );
        if (!ok) throw Exception('Failed to create Zone.');
        
        await state.loadFields();
        // Find the created zone (usually the latest one)
        final reloadedField = state.fields.firstWhere((f) => f.id == widget.field.id);
        if (reloadedField.zones.isNotEmpty) {
          final createdZone = reloadedField.zones.last;
          // Assign checked valves to this zone
          for (var entry in _selectedValvesForZone.entries) {
            if (entry.value) {
              await state.assignValveToZone(
                valveId: entry.key,
                zoneId: createdZone.id,
                fieldId: widget.field.id,
              );
            }
          }
        }
        setState(() => _currentStep = 6);
      } else if (_currentStep == 6) {
        // Step 7: Finish
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final currentField = state.fields.firstWhere((f) => f.id == widget.field.id, orElse: () => widget.field);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Commissioning Wizard'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Step Tracker Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: List.generate(13, (index) {
                if (index.isEven) {
                  final stepIndex = index ~/ 2;
                  final isCompleted = stepIndex < _currentStep;
                  final isCurrent = stepIndex == _currentStep;
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : isCurrent
                              ? const Color(0xFF2D7A3A)
                              : Colors.grey[300],
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCurrent || isCompleted ? Colors.white : Colors.grey[600],
                              ),
                            ),
                    ),
                  );
                } else {
                  final lineIndex = index ~/ 2;
                  final isCompleted = lineIndex < _currentStep;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? const Color(0xFF10B981) : Colors.grey[300],
                    ),
                  );
                }
              }),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(state, currentField),
            ),
          ),

          // Bottom Button Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    onPressed: _isLoading ? null : _prevStep,
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 16),
                ],
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF2D7A3A))
                    : Expanded(
                        child: PrimaryButton(
                          label: _currentStep == 6 ? 'Finish' : 'Next',
                          onPressed: _nextStep,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(AppState state, Field field) {
    switch (_currentStep) {
      case 0:
        return _stepRegisterMaster();
      case 1:
        return _stepAddSlaveBoards(state);
      case 2:
        return _stepSetModbusAddresses(state);
      case 3:
        return _stepDiscoverOutputs(state);
      case 4:
        return _stepNameValves();
      case 5:
        return _stepCreateZones(field);
      case 6:
        return _stepTestIrrigation(field);
      default:
        return const SizedBox();
    }
  }

  // --- STEP 1: REGISTER MASTER ---
  Widget _stepRegisterMaster() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Register Master Controller',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please input the unique identifier and details from the physical Master Controller box.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _deviceUidCtrl,
          label: 'Device UID / Serial Number',
          hint: 'e.g., MASTER-001',
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _imeiCtrl,
          label: 'SIM IMEI (Optional)',
          hint: '15-digit number',
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _simCtrl,
          label: 'SIM Card Phone Number (Optional)',
          hint: 'Include country code',
        ),
        const SizedBox(height: 16),
        const Text('Connection Type', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _connectionType,
          items: const [
            DropdownMenuItem(value: 'gsm4g', child: Text('4G GSM cellular')),
            DropdownMenuItem(value: 'gsm5g', child: Text('5G GSM cellular')),
            DropdownMenuItem(value: 'wifi', child: Text('WiFi Local network')),
            DropdownMenuItem(value: 'loraGateway', child: Text('LoRa Gateway link')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _connectionType = v);
          },
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
        ),
      ],
    );
  }

  // --- STEP 2: ADD SLAVE BOARDS ---
  Widget _stepAddSlaveBoards(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Add Slave Boards',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add the extension Modbus relay boards connected to the Master Controller via RS485 wiring.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Register New Slave Board', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                AppTextField(controller: _slaveNameCtrl, label: 'Slave Board Name', hint: 'e.g., Relays East'),
                const SizedBox(height: 12),
                AppTextField(controller: _slaveUidCtrl, label: 'Device UID', hint: 'e.g., SLAVE-001'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _slaveAddrCtrl,
                  label: 'Modbus Unit ID / Address',
                  hint: '1 to 247',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Add Board',
                  onPressed: () async {
                    if (_slaveNameCtrl.text.isEmpty || _slaveUidCtrl.text.isEmpty) return;
                    final addr = int.tryParse(_slaveAddrCtrl.text.trim()) ?? 1;
                    setState(() => _isLoading = true);
                    final ok = await state.createSlaveBoard(
                      widget.field.masterController!.id,
                      name: _slaveNameCtrl.text.trim(),
                      deviceUid: _slaveUidCtrl.text.trim(),
                      modbusAddress: addr,
                    );
                    setState(() => _isLoading = false);
                    if (ok) {
                      _slaveNameCtrl.clear();
                      _slaveUidCtrl.clear();
                      _slaveAddrCtrl.text = '${addr + 1}';
                      _loadSlaves();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Connected Slave Boards:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (state.slaveBoards.isEmpty)
          const Text('No slave boards added yet.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.slaveBoards.length,
            itemBuilder: (context, idx) {
              final sb = state.slaveBoards[idx];
              return ListTile(
                title: Text(sb.name),
                subtitle: Text('UID: ${sb.deviceUid} | Modbus Address: ${sb.modbusAddress}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: () async {
                    await state.deleteSlaveBoard(sb.id);
                    _loadSlaves();
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // --- STEP 3: SET MODBUS ADDRESSES ---
  Widget _stepSetModbusAddresses(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Verify Modbus Address Configuration',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ensure the physical DIP switches on each slave board match the Modbus Address set below.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.slaveBoards.length,
          itemBuilder: (context, index) {
            final sb = state.slaveBoards[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(sb.name),
                subtitle: Text('Device UID: ${sb.deviceUid}'),
                trailing: SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    value: sb.modbusAddress,
                    items: List.generate(247, (i) => i + 1)
                        .map((i) => DropdownMenuItem(value: i, child: Text('ID $i')))
                        .toList(),
                    onChanged: (newAddr) async {
                      if (newAddr != null) {
                        await state.createSlaveBoard(
                          widget.field.masterController!.id,
                          name: sb.name,
                          deviceUid: sb.deviceUid,
                          modbusAddress: newAddr,
                        );
                        _loadSlaves();
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STEP 4: DISCOVER & TEST OUTPUTS ---
  Widget _stepDiscoverOutputs(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Discover & Test Outputs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Trigger output relays one by one. Once you identify which field sector opens, record the mapping.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (state.slaveBoards.isEmpty)
          const Text('Please register a Slave Board first.')
        else ...[
          DropdownButtonFormField<SlaveBoard>(
            value: _selectedTestBoard,
            items: state.slaveBoards
                .map((sb) => DropdownMenuItem(value: sb, child: Text(sb.name)))
                .toList(),
            onChanged: (sb) {
              if (sb != null) setState(() => _selectedTestBoard = sb);
            },
            decoration: const InputDecoration(labelText: 'Select Board to Test'),
          ),
          const SizedBox(height: 16),
          const Text('Select Output Relay (Coil Address):', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: 8, // Support testing first 8 coils for discovery
            itemBuilder: (context, coil) {
              final isSel = _selectedCoil == coil;
              return ChoiceChip(
                label: Text('Coil $coil'),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _selectedCoil = coil);
                },
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: _isTestingCoil ? 'Testing Pulse...' : 'Pulse Test Output',
                  onPressed: _isTestingCoil
                      ? null
                      : () async {
                          if (_selectedTestBoard == null) return;
                          setState(() => _isTestingCoil = true);
                          // Send a manual test command via simulated state delay or MQTT trigger
                          await Future.delayed(const Duration(seconds: 2));
                          setState(() {
                            _isTestingCoil = false;
                            // Add discovered valve configuration helper details
                            final key = '${_selectedTestBoard!.id}_$_selectedCoil';
                            if (!_newValves.any((v) => v['key'] == key)) {
                              _newValves.add({
                                'key': key,
                                'slaveBoardId': _selectedTestBoard!.id,
                                'slaveBoardName': _selectedTestBoard!.name,
                                'coilAddress': _selectedCoil,
                                'deviceUid': 'VALVE-${_selectedTestBoard!.deviceUid}-$_selectedCoil',
                              });
                              _valveNameControllers[key] = TextEditingController();
                            }
                          });
                        },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // --- STEP 5: NAME VALVES ---
  Widget _stepNameValves() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 5: Name Discovered Valves',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Provide friendly, meaningful names for the valves you tested in the previous step.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (_newValves.isEmpty)
          const Text('No tested valves recorded. Please go back and pulse-test at least one coil.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _newValves.length,
            itemBuilder: (context, idx) {
              final v = _newValves[idx];
              final key = v['key'] as String;
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Board: ${v['slaveBoardName']} | Coil Output: ${v['coilAddress']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _valveNameControllers[key]!,
                        label: 'Valve Friendly Name',
                        hint: 'e.g., Tomato Block Front',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // --- STEP 6: CREATE ZONES ---
  Widget _stepCreateZones(Field field) {
    // Gather all valves currently in the field
    final List<Valve> allValves = [];
    for (var z in field.zones) {
      allValves.addAll(z.valves);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 6: Create Irrigation Zones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Group your newly added valves into logical watering zones (e.g., Tomato field, orchard block).',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _zoneNameCtrl,
          label: 'Zone Name',
          hint: 'e.g., Tomatoes Area',
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _zoneDescCtrl,
          label: 'Description / Notes',
          hint: 'e.g., Solenoids for tomato drip blocks',
        ),
        const SizedBox(height: 20),
        const Text('Select Valves to include in this Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (allValves.isEmpty)
          const Text('No configured valves available in this field.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allValves.length,
            itemBuilder: (context, idx) {
              final v = allValves[idx];
              final isChecked = _selectedValvesForZone[v.id] ?? false;
              return CheckboxListTile(
                title: Text(v.name),
                subtitle: Text('Coil: ${v.valveNumber - 1} | Board: ${v.slaveBoardName ?? 'N/A'}'),
                value: isChecked,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedValvesForZone[v.id] = val;
                    });
                  }
                },
              );
            },
          ),
      ],
    );
  }

  // --- STEP 7: TEST IRRIGATION ---
  Widget _stepTestIrrigation(Field field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 7: Run Test Irrigation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Verify complete system installation. Run a short manual pulse on your new zones.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (field.zones.isEmpty)
          const Text('No zones configured. Please create a zone first.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: field.zones.length,
            itemBuilder: (context, idx) {
              final z = field.zones[idx];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(z.name),
                  subtitle: Text('${z.valves.length} Valves | Status: ${z.status}'),
                  trailing: TextButton(
                    child: const Text('TEST ZONE'),
                    onPressed: () async {
                      final state = context.read<AppState>();
                      bool ok = true;
                      try {
                        await state.executeCommand(
                          targetType: 'zone',
                          targetId: z.id,
                          action: 'open',
                        );
                      } catch (_) {
                        ok = false;
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Test command dispatched successfully!' : 'Failed to dispatch command.'),
                            backgroundColor: ok ? const Color(0xFF2D7A3A) : const Color(0xFFDC2626),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
