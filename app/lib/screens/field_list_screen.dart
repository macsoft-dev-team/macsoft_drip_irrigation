import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/field.dart';
import '../widgets/field_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_loading_button.dart';
import '../widgets/app_text_field.dart';
import 'field_detail_screen.dart';

class FieldListScreen extends StatefulWidget {
  const FieldListScreen({super.key});

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
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
