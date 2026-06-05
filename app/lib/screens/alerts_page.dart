import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/alert.dart';
import '../widgets/alert_tile.dart';
import '../widgets/empty_state.dart';

class AlertsPage extends StatefulWidget {
  final List<Alert> alerts; // For backward compatibility with constructor signature
  const AlertsPage({super.key, this.alerts = const []});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String _filter = 'all'; // all, unread, read

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF2D7A3A)),
            tooltip: 'Mark all as read',
            onPressed: () {
              final state = context.read<AppState>();
              for (var alert in state.alerts) {
                state.markAlertAsRead(alert.id);
              }
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.alertsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Alert> filteredAlerts;
          if (_filter == 'unread') {
            filteredAlerts = state.alerts.where((a) => !a.isRead).toList();
          } else if (_filter == 'read') {
            filteredAlerts = state.alerts.where((a) => a.isRead).toList();
          } else {
            filteredAlerts = state.alerts;
          }

          if (state.alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Alerts Yet',
              description: 'You will receive notifications here about valve status, offline controllers, and support updates.',
            );
          }

          return Column(
            children: [
              // Filters Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Unread',
                      selected: _filter == 'unread',
                      onTap: () => setState(() => _filter = 'unread'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Read',
                      selected: _filter == 'read',
                      onTap: () => setState(() => _filter = 'read'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredAlerts.isEmpty
                    ? Center(
                        child: Text(
                          'No ${_filter == 'all' ? '' : _filter} alerts found.',
                          style: const TextStyle(color: Color(0xFF8A958A)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => state.loadAlerts(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredAlerts.length,
                          separatorBuilder: (context, i) => const Divider(height: 1, thickness: 0.8, color: Color(0xFFECEFF1)),
                          itemBuilder: (context, i) {
                            final alert = filteredAlerts[i];
                            return AlertTile(
                              alert: alert,
                              onTap: () {
                                state.markAlertAsRead(alert.id);
                                _handleAlertNavigation(context, alert, state);
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleAlertNavigation(BuildContext context, Alert alert, AppState state) {
    // Navigate based on alert type if applicable
    if (alert.type == 'masterOffline') {
      // Find matching field
      final field = state.fields.firstWhere((f) => f.masterController?.deviceUid == 'MC-SOUTH-G1', orElse: () => state.fields[0]);
      Navigator.pushNamed(context, '/fields/${field.id}');
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D7A3A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : const Color(0xFF546E7A),
          ),
        ),
      ),
    );
  }
}
