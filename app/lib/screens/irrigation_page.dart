import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
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

class _IrrigationPageState extends State<IrrigationPage> with SingleTickerProviderStateMixin {
  int _selectedFieldIdx = 0;
  final Map<String, bool> _expandedZones = {};
  
  // Local valve states to simulate interactive open/close toggles in high-fidelity
  final Map<String, bool> _valveStates = {};
  bool _masterValveOpen = true;

  List<Map<String, dynamic>> _customers = [];
  bool _loadingCustomers = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadFields();
      _fetchCustomersIfNeeded();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomersIfNeeded() async {
    final state = context.read<AppState>();
    if (state.user?.isSuperAdmin ?? false) {
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

  // Helper to cycle color schemes for Zone headers
  static const List<(Color, Color, IconData)> _zoneColors = [
    (Color(0xFFE8F5E9), Color(0xFF2D7A3A), Icons.grass_rounded),
    (Color(0xFFE3F2FD), Color(0xFF1565C0), Icons.water_drop_rounded),
    (Color(0xFFFFF3E0), Color(0xFFE65100), Icons.park_rounded),
    (Color(0xFFF3E5F5), Color(0xFF7B1FA2), Icons.local_florist_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final isCustomer = state.user?.role == UserRole.customer;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            title: const Row(
              children: [
                Icon(Icons.water_drop_rounded, color: Color(0xFF2D7A3A), size: 24),
                SizedBox(width: 8),
                Text(
                  'Irrigation Layout',
                  style: TextStyle(
                    color: Color(0xFF1E2A1F),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2D7A3A)),
                onPressed: () => state.loadFields(),
              ),
              if (!isCustomer)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2D7A3A)),
                  onPressed: () => _showFieldFormSheet(context),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: () {
            if (state.fieldsLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2D7A3A)));
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
                      'No irrigation fields found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text('Create your first system layout to begin.'),
                    if (!isCustomer) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showFieldFormSheet(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add System'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D7A3A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(160, 48),
                        ),
                      )
                    ]
                  ],
                ),
              );
            }

            if (_selectedFieldIdx >= state.fields.length) {
              _selectedFieldIdx = 0;
            }
            final field = state.fields[_selectedFieldIdx];

            return Column(
              children: [
                // ── Field Selector Tab Bar ────────────────────────────────────
                if (state.fields.length > 1)
                  _buildFieldSelector(state),

                // Sticky title + Master Valve Hero Card at top
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldTitleRow(context, field, state),
                      const SizedBox(height: 10),
                      _buildMasterValveHero(field),
                      const SizedBox(height: 10),
                      _buildSpecsCard(field),
                    ],
                  ),
                ),

                // Styled Segmented Tab Bar
                _buildTabBar(field),

                // Segmented Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubValvesTab(context, field, isCustomer),
                      _buildScheduleTab(),
                      _buildHistoryTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),

                // Sticky Bottom Actions Row
                _buildBottomActionBar(field, isCustomer),
              ],
            );
          }(),
        );
      },
    );
  }

  Widget _buildFieldSelector(AppState state) {
    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: state.fields.length,
        itemBuilder: (context, i) {
          final isSelected = i == _selectedFieldIdx;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                state.fields[i].name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF1E2A1F),
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedFieldIdx = i;
                  });
                }
              },
              selectedColor: const Color(0xFF2D7A3A),
              backgroundColor: const Color(0xFFF4F6FA),
              checkmarkColor: Colors.white,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldTitleRow(BuildContext context, Field field, AppState state) {
    final isCustomer = state.user?.role == UserRole.customer;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          field.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2A1F),
          ),
        ),
        if (!isCustomer)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF8A958A)),
            onSelected: (val) {
              if (val == 'edit') {
                _showFieldFormSheet(context, field: field);
              } else if (val == 'delete') {
                _confirmDeleteField(context, field);
              } else if (val == 'add_zone') {
                _showZoneFormSheet(context, field);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Field Name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_zone',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Add New Zone'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Field', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Master Valve Widget (Redesigned Light Green Card) ──────────────────────
  Widget _buildMasterValveHero(Field field) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF1E3F20)], // Deep forest green gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            // Valve Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/solenoid_valve.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.settings_input_component_rounded,
                    color: Colors.white70,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Valve Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Master Valve',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981), // Online green
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Main Line',
                    style: TextStyle(
                      color: Color(0xFFA7F3D0), // Light mint text
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Open badge/button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _masterValveOpen = !_masterValveOpen;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Master Valve is now ${_masterValveOpen ? 'Open' : 'Closed'}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _masterValveOpen ? Colors.white.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _masterValveOpen ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _masterValveOpen ? 'Open' : 'Closed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Battery Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.battery_charging_full_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '100%',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsCard(Field field) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSpecColumn(Icons.access_time_rounded, '01:15:30', 'Running Time', const Color(0xFF10B981)),
            _buildSpecColumn(Icons.water_rounded, '24.8 LPM', 'Flow Rate', const Color(0xFF3B82F6)),
            _buildSpecColumn(Icons.speed_rounded, '1.2 Bar', 'Pressure', const Color(0xFFD97706)),
            _buildSpecColumn(Icons.battery_charging_full_rounded, '100%', 'Battery', const Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecColumn(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E2A1F),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Styled Segmented Tab Bar Widget ────────────────────────────────────────
  Widget _buildTabBar(Field field) {
    final totalValvesCount = field.zones.fold<int>(0, (sum, z) => sum + z.valves.length);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black87,
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(
            child: Text(
              'Sub Valves ($totalValvesCount)',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
          const Tab(
            child: Text(
              'Schedule',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
          const Tab(
            child: Text(
              'History',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
          const Tab(
            child: Text(
              'Settings',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub Valves Tab Content ──────────────────────────────────────────────────
  Widget _buildSubValvesTab(BuildContext context, Field field, bool isCustomer) {
    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().loadFields(),
      color: const Color(0xFF2D7A3A),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _buildNestedMasterValveStatusRow(),
          const SizedBox(height: 12),
          _buildSubValvesList(context, field, isCustomer),
          const SizedBox(height: 24),
          const Text(
            "Today's Summary",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2A1F),
            ),
          ),
          const SizedBox(height: 8),
          _buildOverviewSparklines(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Nested Master Valve Status row inside Sub Valves tab
  Widget _buildNestedMasterValveStatusRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _masterValveOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings_input_component_rounded,
              color: _masterValveOpen ? const Color(0xFF16A34A) : const Color(0xFF64748B),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master Valve (M-01)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E2A1F),
                  ),
                ),
                Text(
                  'Signal: Good (-65dBm) • Battery: 100%',
                  style: TextStyle(
                    color: Color(0xFF8A958A),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _masterValveOpen,
            activeColor: const Color(0xFF16A34A),
            onChanged: (val) {
              setState(() {
                _masterValveOpen = val;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Master Valve is now ${_masterValveOpen ? 'Open' : 'Closed'}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Sub Valves Hierarchy tree Widget ───────────────────────────────────────
  Widget _buildSubValvesList(BuildContext context, Field field, bool isCustomer) {
    if (field.zones.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'No zones configured for this field.',
              style: TextStyle(color: Color(0xFF8A958A), fontSize: 13),
            ),
            if (!isCustomer) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showZoneFormSheet(context, field),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Zone'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            ]
          ],
        ),
      );
    }

    return Column(
      children: field.zones.asMap().entries.map((entry) {
        final zoneIdx = entry.key;
        final zone = entry.value;
        final isExpanded = _expandedZones[zone.id] ?? false;
        final zoneColorMeta = _zoneColors[zoneIdx % _zoneColors.length];

        final isFirst = zoneIdx == 0;
        final isLast = zoneIdx == field.zones.length - 1;
        final hasLineBelow = !isLast || isExpanded;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Timeline Line & Avatar Column
              Container(
                width: 36,
                child: Column(
                  children: [
                    // Line above avatar
                    Container(
                      width: 2.5,
                      height: 16,
                      color: isFirst ? Colors.transparent : const Color(0xFF2D7A3A),
                    ),
                    // Avatar centered
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: zoneColorMeta.$1,
                      child: Icon(zoneColorMeta.$3, color: zoneColorMeta.$2, size: 18),
                    ),
                    // Line below avatar
                    Expanded(
                      child: Container(
                        width: 2.5,
                        color: hasLineBelow ? const Color(0xFF2D7A3A) : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right content column (Zone Card)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Zone Row Item
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          zone.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E2A1F)),
                        ),
                        subtitle: Text(
                          '${zone.valves.length} Valves',
                          style: const TextStyle(color: Color(0xFF8A958A), fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Open/Closed general status indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: zone.valves.any((v) => _valveStates[v.id] ?? true)
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                zone.valves.any((v) => _valveStates[v.id] ?? true) ? 'Open' : 'Closed',
                                style: TextStyle(
                                  color: zone.valves.any((v) => _valveStates[v.id] ?? true)
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isCustomer) ...[
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF8A958A)),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showZoneFormSheet(context, field, zone: zone);
                                  } else if (val == 'delete') {
                                    _confirmDeleteZone(context, field, zone);
                                  } else if (val == 'add_valve') {
                                    _showValveFormSheet(context, field, zone);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'add_valve', child: Text('Add Valve')),
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Zone Name')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete Zone', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF8A958A),
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _expandedZones[zone.id] = !isExpanded;
                          });
                        },
                      ),

                      // Nest Valves if Expanded
                      if (isExpanded) ...[
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildValveNestedList(context, field, zone, isCustomer),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildValveNestedList(BuildContext context, Field field, Zone zone, bool isCustomer) {
    if (zone.valves.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'No valves inside this zone.',
              style: TextStyle(color: Color(0xFF8A958A), fontSize: 12),
            ),
            if (!isCustomer) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showValveFormSheet(context, field, zone),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Valve', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D7A3A)),
              ),
            ]
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ...zone.valves.asMap().entries.map((entry) {
            final vIdx = entry.key;
            final valve = entry.value;
            final isLast = vIdx == zone.valves.length - 1;
            final isOpen = _valveStates[valve.id] ?? true;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Tree Line connector column
                  CustomPaint(
                    size: const Size(28, 46),
                    painter: TreeLinePainter(isLast: isLast),
                  ),

                  // Valve status droplet circle
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isOpen ? const Color(0xFFE3F2FD) : const Color(0xFFF1F5F9),
                    child: Icon(
                      isOpen ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                      color: isOpen ? Colors.blue : const Color(0xFF64748B),
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Valve name
                  Expanded(
                    child: Text(
                      valve.name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),

                  // Toggable Open/Closed status badge
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _valveStates[valve.id] = !isOpen;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${valve.name} is now ${!isOpen ? 'Open' : 'Closed'}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOpen ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        isOpen ? 'Open' : 'Closed',
                        style: TextStyle(
                          color: isOpen ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Actions menu
                  if (!isCustomer) ...[
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF8A958A)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showValveFormSheet(context, field, zone, valve: valve);
                        } else if (val == 'delete') {
                          _confirmDeleteValve(context, field, zone, valve);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit Valve')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete Valve', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ] else
                    const SizedBox(width: 24),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Schedules Tab Content ──────────────────────────────────────────────────
  Widget _buildScheduleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildScheduleItem('Morning Cycle', '6:00 AM', '45 mins', 'Everyday', true),
        _buildScheduleItem('Evening Cycle', '6:00 PM', '30 mins', 'Mon, Wed, Fri', true),
        _buildScheduleItem('Night Maintenance', '10:00 PM', '15 mins', 'Sunday', false),
      ],
    );
  }

  Widget _buildScheduleItem(String name, String time, String duration, String frequency, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: active ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
            radius: 18,
            child: Icon(Icons.schedule_rounded, color: active ? const Color(0xFF0284C7) : const Color(0xFF64748B), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E2A1F))),
                const SizedBox(height: 2),
                Text('$time • $duration • $frequency', style: const TextStyle(color: Color(0xFF8A958A), fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: active,
            activeColor: const Color(0xFF0284C7),
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }

  // ── History Tab Content ─────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHistoryItem('Morning Irrigation', 'Today, 6:00 AM', 'Completed successfully • 680 L', Icons.check_circle_rounded, const Color(0xFF16A34A)),
        _buildHistoryItem('Evening Irrigation', 'Yesterday, 6:00 PM', 'Completed successfully • 450 L', Icons.check_circle_rounded, const Color(0xFF16A34A)),
        _buildHistoryItem('Low Pressure Alert', '2 days ago, 6:15 PM', 'Resolved automatically', Icons.warning_rounded, const Color(0xFFD97706)),
      ],
    );
  }

  Widget _buildHistoryItem(String title, String time, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E2A1F))),
                const SizedBox(height: 2),
                Text('$time • $desc', style: const TextStyle(color: Color(0xFF8A958A), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Settings Tab Content ────────────────────────────────────────────────────
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingTile('Soil Moisture Threshold', '45%', Icons.opacity_rounded),
        _buildSettingTile('Rain Sensor Bypass', 'Disabled', Icons.umbrella_rounded),
        _buildSettingTile('Smart Weather Adjustments', 'Enabled (85% scaling)', Icons.cloud_rounded),
        _buildSettingTile('Hardware Controller Model', 'DripFlow Pro v2', Icons.developer_board_rounded),
      ],
    );
  }

  Widget _buildSettingTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF475569), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E2A1F))),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  // ── Today's Overview Sparklines (Exactly 2 Sparklines) ────────────────────
  Widget _buildOverviewSparklines() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildSparklineCard(
            'Water Used',
            '680 L',
            '▲ 12% vs yesterday',
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
            const [120, 240, 190, 380, 290, 480, 680],
            Icons.water_drop_rounded,
          ),
          const SizedBox(width: 10),
          _buildSparklineCard(
            'Irrigation Time',
            '2h 35m',
            '▲ 8% vs yesterday',
            const Color(0xFF3B82F6),
            const Color(0xFFEFF6FF),
            const [60, 95, 110, 150, 130, 145, 155],
            Icons.access_time_filled_rounded,
          ),
          const SizedBox(width: 10),
          _buildSparklineCard(
            'System Efficiency',
            '75%',
            '▲ 5% vs yesterday',
            const Color(0xFF8B5CF6),
            const Color(0xFFFAF5FF),
            const [70, 72, 71, 74, 73, 75, 75],
            Icons.speed_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSparklineCard(
    String title,
    String value,
    String comparison,
    Color color,
    Color bgColor,
    List<double> dataPoints,
    IconData icon,
  ) {
    final trendColor = const Color(0xFF16A34A);

    return Container(
      width: 140, // Set fixed width so they align nicely in horizontal scroll
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E2A1F),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            comparison,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: trendColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            width: double.infinity,
            child: CustomPaint(
              painter: SparklinePainter(dataPoints, color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Redesigned 3-Button Actions Panel at Bottom ─────────────────────────────
  Widget _buildBottomActionBar(Field field, bool isCustomer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('Manual Irrigation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F5132), // Dark green background
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Triggering Manual Irrigation...')),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              offset: const Offset(0, -110),
              onSelected: (val) {
                if (val == 'edit') {
                  _showFieldFormSheet(context, field: field);
                } else if (val == 'test') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starting Valve Diagnostic Test...')),
                  );
                }
              },
              itemBuilder: (context) => [
                if (!isCustomer)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Field'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'test',
                  child: Row(
                    children: [
                      Icon(Icons.science_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Test Valve'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Icon(
                  Icons.tune_rounded, // Sliders icon
                  color: Color(0xFF475569),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
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
            final isSuperadmin = state.user?.isSuperAdmin ?? false;
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D7A3A),
                      foregroundColor: Colors.white,
                    ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A3A),
                  foregroundColor: Colors.white,
                ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7A3A),
                  foregroundColor: Colors.white,
                ),
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

// ── TreeLinePainter ──────────────────────────────────────────────────────────
class TreeLinePainter extends CustomPainter {
  final bool isLast;

  TreeLinePainter({required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D7A3A)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw vertical timeline line
    final double startY = 0;
    final double endY = isLast ? size.height / 2 : size.height;
    canvas.drawLine(Offset(size.width / 2, startY), Offset(size.width / 2, endY), paint);

    // Draw horizontal branch connector
    canvas.drawLine(Offset(size.width / 2, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant TreeLinePainter oldDelegate) => oldDelegate.isLast != isLast;
}

// ── SparklinePainter ─────────────────────────────────────────────────────────
class SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  SparklinePainter(this.dataPoints, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final double stepX = size.width / (dataPoints.length - 1);
    final double maxVal = dataPoints.reduce(math.max);
    final double minVal = dataPoints.reduce(math.min);
    final double range = (maxVal - minVal == 0) ? 1.0 : (maxVal - minVal);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < dataPoints.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((dataPoints[i] - minVal) / range) * (size.height - 4) - 2;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - ((dataPoints[i - 1] - minVal) / range) * (size.height - 4) - 2;
        
        path.cubicTo(
          prevX + stepX / 2, prevY,
          x - stepX / 2, y,
          x, y,
        );
        fillPath.cubicTo(
          prevX + stepX / 2, prevY,
          x - stepX / 2, y,
          x, y,
        );
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) => true;
}
