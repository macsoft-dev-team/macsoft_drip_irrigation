import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/field.dart';
import '../models/app_user.dart';
import '../models/zone.dart';
import '../models/valve.dart';
import '../widgets/field_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_loading_button.dart';
import '../widgets/app_text_field.dart';
import 'field_detail_screen.dart';
import 'farmer_detail_screen.dart';

class HierarchicalFarmer {
  final AppUser farmer;
  final List<HierarchicalField> fields;

  HierarchicalFarmer({required this.farmer, required this.fields});
}

class HierarchicalField {
  final Field field;
  final List<HierarchicalZone> zones;

  HierarchicalField({required this.field, required this.zones});
}

class HierarchicalZone {
  final Zone zone;
  final List<Valve> valves;

  HierarchicalZone({required this.zone, required this.valves});
}

class FieldListScreen extends StatefulWidget {
  const FieldListScreen({super.key});

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  String _searchQuery = '';
  String _controllerStatusFilter = 'All'; // All, Online, Offline
  String _valveStatusFilter = 'All'; // All, Open, Closed
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadFields();
      if (state.user?.isAdmin == true) {
        state.loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HierarchicalFarmer> _buildFilteredHierarchy(AppState state) {
    final query = _searchQuery.toLowerCase();
    
    // Get all farmers
    final farmers = state.users.where((u) => u.role == UserRole.customer).toList();
    
    // Group fields by farmerId
    final Map<String, List<Field>> groupedFields = {};
    for (final field in state.fields) {
      groupedFields.putIfAbsent(field.farmerId, () => []).add(field);
    }
    
    final List<HierarchicalFarmer> result = [];
    
    for (final entry in groupedFields.entries) {
      final farmerId = entry.key;
      final fieldsList = entry.value;
      
      final farmer = farmers.firstWhere(
        (u) => u.tenantId == farmerId,
        orElse: () => AppUser(
          id: '',
          name: 'Farmer #$farmerId',
          role: UserRole.customer,
          tenantId: farmerId,
          phone: 'No phone info',
        ),
      );
      
      final List<HierarchicalField> hFields = [];
      for (final field in fieldsList) {
        final List<HierarchicalZone> hZones = [];
        for (final zone in field.zones) {
          final List<Valve> filteredValves = [];
          for (final valve in zone.valves) {
            if (_valveStatusFilter != 'All') {
              if (_valveStatusFilter.toLowerCase() != valve.status.toLowerCase()) {
                continue;
              }
            }
            
            final matchesValve = query.isEmpty ||
                valve.name.toLowerCase().contains(query) ||
                valve.deviceUid.toLowerCase().contains(query) ||
                valve.id.toLowerCase().contains(query);
                
            if (matchesValve) {
              filteredValves.add(valve);
            }
          }
          
          final matchesZone = query.isEmpty ||
              zone.name.toLowerCase().contains(query) ||
              (zone.description ?? '').toLowerCase().contains(query) ||
              zone.id.toLowerCase().contains(query);
              
          if (matchesZone || filteredValves.isNotEmpty) {
            final valvesToInclude = matchesZone
                ? zone.valves.where((v) {
                    if (_valveStatusFilter != 'All') {
                      return v.status.toLowerCase() == _valveStatusFilter.toLowerCase();
                    }
                    return true;
                  }).toList()
                : filteredValves;
                
            hZones.add(HierarchicalZone(zone: zone, valves: valvesToInclude));
          }
        }
        
        if (_controllerStatusFilter != 'All') {
          final mcStatus = field.masterController?.status.toLowerCase() ?? 'offline';
          if (_controllerStatusFilter.toLowerCase() != mcStatus) {
            continue;
          }
        }
        
        final matchesField = query.isEmpty ||
            field.name.toLowerCase().contains(query) ||
            (field.locationName ?? '').toLowerCase().contains(query) ||
            field.id.toLowerCase().contains(query);
            
        if (matchesField || hZones.isNotEmpty) {
          final zonesToInclude = matchesField
              ? field.zones.map((z) {
                  final valves = z.valves.where((v) {
                    if (_valveStatusFilter != 'All') {
                      return v.status.toLowerCase() == _valveStatusFilter.toLowerCase();
                    }
                    return true;
                  }).toList();
                  return HierarchicalZone(zone: z, valves: valves);
                }).toList()
              : hZones;
              
          hFields.add(HierarchicalField(field: field, zones: zonesToInclude));
        }
      }
      
      final matchesFarmer = query.isEmpty ||
          (farmer.name ?? '').toLowerCase().contains(query) ||
          (farmer.phone ?? '').toLowerCase().contains(query) ||
          (farmer.email ?? '').toLowerCase().contains(query) ||
          farmer.tenantId.toString().toLowerCase().contains(query);
          
      if (matchesFarmer || hFields.isNotEmpty) {
        final fieldsToInclude = matchesFarmer
            ? fieldsList.map((f) {
                final zones = f.zones.map((z) {
                  final valves = z.valves.where((v) {
                    if (_valveStatusFilter != 'All') {
                      return v.status.toLowerCase() == _valveStatusFilter.toLowerCase();
                    }
                    return true;
                  }).toList();
                  return HierarchicalZone(zone: z, valves: valves);
                }).toList();
                return HierarchicalField(field: f, zones: zones);
              }).toList()
            : hFields;
            
        result.add(HierarchicalFarmer(farmer: farmer, fields: fieldsToInclude));
      }
    }
    
    return result;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _controllerStatusFilter = 'All';
                            _valveStatusFilter = 'All';
                          });
                          setState(() {});
                        },
                        child: const Text('Reset', style: TextStyle(color: Color(0xFF2D7A3A))),
                      )
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Controller Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A5568))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Online', 'Offline'].map((status) {
                      final isSelected = _controllerStatusFilter == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2D7A3A).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF2D7A3A) : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _controllerStatusFilter = status;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Valve Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A5568))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Open', 'Closed'].map((status) {
                      final isSelected = _valveStatusFilter == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2D7A3A).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF2D7A3A) : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            _valveStatusFilter = status;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminHierarchy(AppState state) {
    final filtered = _buildFilteredHierarchy(state);
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search farmers, fields, zones, valves...',
                  border: InputBorder.none,
                  filled: false,
                ),
                style: const TextStyle(color: Color(0xFF1A1F36), fontSize: 16),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : const Text('Farmers & Fields'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: const Color(0xFF2D7A3A)),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: (_controllerStatusFilter != 'All' || _valveStatusFilter != 'All')
                  ? const Color(0xFF2D7A3A)
                  : Colors.grey,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: (state.fieldsLoading || state.usersLoading)
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No Matches Found',
                  description: 'Try adjusting your search query or status filters.',
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await state.loadFields();
                    await state.loadUsers();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final hFarmer = filtered[index];
                      return _buildFarmerCard(hFarmer);
                    },
                  ),
                ),
    );
  }

  Widget _buildFarmerCard(HierarchicalFarmer hFarmer) {
    final farmer = hFarmer.farmer;
    final fieldsCount = hFarmer.fields.length;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
          child: const Icon(Icons.person_rounded, color: Color(0xFF2D7A3A)),
        ),
        title: Text(
          farmer.name ?? 'Unknown Farmer',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F), fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              farmer.phone ?? 'No Phone',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '$fieldsCount ${fieldsCount == 1 ? "Field" : "Fields"} linked',
              style: const TextStyle(color: Color(0xFF2D7A3A), fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmerDetailScreen(farmer: farmer),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldTile(HierarchicalField hf) {
    final field = hf.field;
    final isOnline = field.masterController?.status == 'online';
    
    return Card(
      color: Colors.grey.shade50,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isOnline ? Colors.green : Colors.grey).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.agriculture_rounded,
              color: isOnline ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          title: Text(
            field.name,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1F36), fontSize: 14),
          ),
          subtitle: Text(
            '${field.locationName ?? "No location"} • ${field.areaAcres ?? 0} acres',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          children: [
            if (hf.zones.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No zones configured.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Column(
                  children: hf.zones.map((hz) => _buildZoneTile(hz, field)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneTile(HierarchicalZone hz, Field field) {
    final zone = hz.zone;
    
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          leading: const Icon(Icons.grid_goldenratio_rounded, color: Colors.blueGrey, size: 18),
          title: Text(
            zone.name,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1F36), fontSize: 13),
          ),
          subtitle: Text(
            zone.description ?? 'No description',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          children: [
            if (hz.valves.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6.0),
                child: Text('No matching valves.', style: TextStyle(color: Colors.grey, fontSize: 11)),
              )
            else
              Column(
                children: hz.valves.map((v) => _buildValveTile(v, zone, field)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValveTile(Valve valve, Zone zone, Field field) {
    final isOpen = valve.status == 'open';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(
          Icons.water_drop_outlined,
          color: isOpen ? Colors.blue : Colors.grey,
          size: 16,
        ),
        title: Text(
          valve.name,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1A1F36), fontSize: 12),
        ),
        subtitle: Text(
          'Coil: ${valve.valveNumber - 1} • ${valve.deviceUid}',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isOpen ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            valve.status.toUpperCase(),
            style: TextStyle(
              color: isOpen ? Colors.blue.shade700 : Colors.grey.shade600,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FieldDetailScreen(fieldId: field.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFarmerFields(AppState state) {
    final canAdd = state.user == null || state.user!.canManageFields;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fields'),
        actions: [
          if (canAdd)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2D7A3A), size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FieldFormScreen()),
                );
              },
            ),
        ],
      ),
      body: state.fieldsLoading
          ? const Center(child: CircularProgressIndicator())
          : state.fields.isEmpty
              ? EmptyState(
                  icon: Icons.map_outlined,
                  title: 'No Fields Found',
                  description: 'Start by adding your first agricultural field and linking its master controller.',
                  actionLabel: canAdd ? 'Add Field' : null,
                  onAction: canAdd
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FieldFormScreen()),
                          );
                        }
                      : null,
                )
              : RefreshIndicator(
                  onRefresh: () => state.loadFields(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: state.fields.length,
                    itemBuilder: (context, index) {
                      final field = state.fields[index];
                      return FieldCard(
                        field: field,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FieldDetailScreen(fieldId: field.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final isAdmin = state.user?.isAdmin ?? false;
        if (isAdmin) {
          return _buildAdminHierarchy(state);
        } else {
          return _buildFarmerFields(state);
        }
      },
    );
  }
}

class FieldFormScreen extends StatefulWidget {
  final Field? field;
  const FieldFormScreen({super.key, this.field});

  @override
  State<FieldFormScreen> createState() => _FieldFormScreenState();
}

class _FieldFormScreenState extends State<FieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _areaController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field?.name ?? '');
    _locationController = TextEditingController(text: widget.field?.locationName ?? '');
    _latController = TextEditingController(text: widget.field?.latitude?.toString() ?? '');
    _lngController = TextEditingController(text: widget.field?.longitude?.toString() ?? '');
    _areaController = TextEditingController(text: widget.field?.areaAcres?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _saveField() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final locationName = _locationController.text.trim();
    final latitude = double.tryParse(_latController.text) ?? 0.0;
    final longitude = double.tryParse(_lngController.text) ?? 0.0;
    final areaAcres = double.tryParse(_areaController.text) ?? 0.0;

    final state = context.read<AppState>();
    bool ok;

    if (widget.field == null) {
      ok = await state.createField(
        name: name,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        areaAcres: areaAcres,
      );
    } else {
      ok = await state.updateField(
        id: widget.field!.id,
        name: name,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        areaAcres: areaAcres,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.field == null ? 'Field created successfully' : 'Field updated successfully'),
          backgroundColor: const Color(0xFF2D7A3A),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save field. Please try again.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.field != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Field' : 'Add Field'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              AppTextField(
                label: 'Field Name',
                hint: 'e.g. Sugar Cane Block A',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Location Name',
                hint: 'e.g. Near West Well, gate #3',
                controller: _locationController,
                validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      hint: 'e.g. 19.0760',
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      hint: 'e.g. 72.8777',
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Area (Acres)',
                hint: 'e.g. 12.5',
                controller: _areaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Area is required' : null,
              ),
              const SizedBox(height: 32),
              AppLoadingButton(
                label: isEdit ? 'Update Field' : 'Save Field',
                isLoading: _isLoading,
                onPressed: _saveField,
                color: const Color(0xFF2D7A3A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
