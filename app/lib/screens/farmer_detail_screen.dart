import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/app_user.dart';
import '../models/field.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/confirm_action_dialog.dart';
import 'field_detail_screen.dart';
import 'schedule_list_screen.dart';
import 'commissioning_wizard_page.dart';
import 'field_list_screen.dart';

class FarmerDetailScreen extends StatefulWidget {
  final AppUser farmer;
  const FarmerDetailScreen({super.key, required this.farmer});

  @override
  State<FarmerDetailScreen> createState() => _FarmerDetailScreenState();
}

class _FarmerDetailScreenState extends State<FarmerDetailScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadFields();
      state.loadSchedules();
      state.loadAlerts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePump(BuildContext context, AppState state, String mcId, bool start) async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: start ? 'Start Pump Motor' : 'Stop Pump Motor',
      content: start
          ? 'Are you sure you want to turn ON the water pump motor?'
          : 'Are you sure you want to turn OFF the water pump motor?',
      isDestructive: !start,
    );

    if (confirmed && context.mounted) {
      final ok = await state.controlMotor(mcId, start ? 'start' : 'stop');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Pump motor command dispatched successfully.'
                : 'Failed to dispatch command to pump motor.'),
            backgroundColor: ok ? const Color(0xFF2D7A3A) : const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Widget _buildMotorControl(BuildContext context, AppState state, Field field) {
    final mc = field.masterController;
    if (mc == null) return const SizedBox();

    final isPumpRunning = mc.motorStatus == 'on';
    final isOnline = mc.isOnline;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      field.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2A1F),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPumpRunning
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFF9CA3AF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPumpRunning ? 'RUNNING' : 'STOPPED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isPumpRunning ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Controller: ${mc.deviceUid} • Status: ${mc.status.toUpperCase()}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: isOnline ? () => _togglePump(context, state, mc.id, !isPumpRunning) : null,
                icon: Icon(
                  isPumpRunning ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
                  size: 16,
                ),
                label: Text(
                  isPumpRunning ? 'Stop Pump Motor' : 'Start Pump Motor',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPumpRunning ? const Color(0xFFEF4444) : const Color(0xFF2D7A3A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (!isOnline) ...[
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Motor controls disabled: Master Controller is offline.',
                  style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          title: Text(widget.farmer.name ?? 'Farmer Details'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
              Tab(icon: Icon(Icons.agriculture_outlined), text: 'Fields List'),
            ],
            indicatorColor: Color(0xFF2D7A3A),
            labelColor: Color(0xFF2D7A3A),
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: Consumer<AppState>(
          builder: (context, state, _) {
            final farmerFields = state.fields
                .where((f) => f.farmerId == widget.farmer.tenantId)
                .toList();

            return TabBarView(
              children: [
                _buildDashboardTab(state, farmerFields),
                _buildFieldsTab(state, farmerFields),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardTab(AppState state, List<Field> farmerFields) {
    final int totalFields = farmerFields.length;
    final int onlineMasters = farmerFields
        .where((f) => f.masterController?.isOnline ?? false)
        .length;

    int openValves = 0;
    for (var f in farmerFields) {
      for (var z in f.zones) {
        openValves += z.valves.where((v) => v.status == 'open').length;
      }
    }

    final int runningMotors = farmerFields
        .where((f) => f.masterController?.motorStatus == 'on')
        .length;

    final int activeSchedules = state.schedules
        .where((s) => farmerFields.any((f) => f.id == s.fieldId) && s.status == 'active')
        .length;

    final int activeAlerts = state.alerts.where((a) => !a.isRead).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farmer Info Card
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF2D7A3A), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.farmer.name ?? 'Unknown Farmer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E2A1F)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${widget.farmer.phone ?? "N/A"}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        Text(
                          'ID / Tenant: ${widget.farmer.tenantId ?? "N/A"}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Metrics Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              DashboardMetricCard(
                title: 'Farmer Fields',
                value: '$totalFields',
                icon: Icons.grid_on_rounded,
                color: const Color(0xFF2D7A3A),
              ),
              DashboardMetricCard(
                title: 'Online Controllers',
                value: '$onlineMasters/$totalFields',
                icon: Icons.wifi,
                color: const Color(0xFF3B82F6),
              ),
              DashboardMetricCard(
                title: 'Active Valves',
                value: '$openValves',
                icon: Icons.water_drop,
                color: const Color(0xFF10B981),
              ),
              DashboardMetricCard(
                title: 'Pumps Running',
                value: '$runningMotors',
                icon: Icons.bolt_rounded,
                color: const Color(0xFFEF4444),
              ),
              DashboardMetricCard(
                title: 'Active Schedules',
                value: '$activeSchedules',
                icon: Icons.calendar_month,
                color: const Color(0xFFF59E0B),
              ),
              DashboardMetricCard(
                title: 'System Alerts',
                value: '$activeAlerts',
                icon: Icons.notifications_active,
                color: const Color(0xFFEC4899),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Pump Controls Title
          if (farmerFields.any((f) => f.masterController != null)) ...[
            const Text(
              'Pump Motor Quick Controls',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
            ),
            const SizedBox(height: 12),
            ...farmerFields.map((f) => _buildMotorControl(context, state, f)),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldsTab(AppState state, List<Field> farmerFields) {
    final query = _searchQuery.toLowerCase();
    final filteredFields = farmerFields.where((f) {
      final nameMatch = f.name.toLowerCase().contains(query);
      final locMatch = (f.locationName ?? '').toLowerCase().contains(query);
      final controllerMatch = (f.masterController?.deviceUid ?? '').toLowerCase().contains(query);
      return nameMatch || locMatch || controllerMatch;
    }).toList();

    final isAdmin = state.user?.isAdmin ?? false;

    return Column(
      children: [
        // Search Bar & Add Button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search fields by name or location...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.add_location_alt_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2D7A3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FieldFormScreen(farmerId: widget.farmer.tenantId),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        // Fields List
        Expanded(
          child: filteredFields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No fields matching "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFields.length,
                  itemBuilder: (context, idx) {
                    final field = filteredFields[idx];
                    final isOnline = field.masterController?.isOnline ?? false;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FieldDetailScreen(fieldId: field.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          field.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1A1F36),
                                          ),
                                        ),
                                        Text(
                                          '${field.locationName ?? "No location"} • ${field.areaAcres ?? 0} acres',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Schedule Button
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ScheduleFormScreen(initialFieldId: field.id),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.calendar_month_outlined, size: 16),
                                      label: const Text('Schedule'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF2D7A3A),
                                        side: const BorderSide(color: Color(0xFF2D7A3A)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  // Commissioning Wizard (Visible ONLY to Admin)
                                  if (isAdmin) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CommissioningWizardPage(field: field),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.build_rounded, size: 16),
                                        label: const Text('Commission'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2D7A3A),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
