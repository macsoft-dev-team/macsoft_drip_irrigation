import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/support_ticket.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = "medium";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load tickets if empty or refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadFields(); // ensures fields are loaded for ticket dropdown
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Support Center")),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Color(0xFF1E4D2B),
              labelColor: Color(0xFF1E4D2B),
              tabs: [
                Tab(text: "My Tickets"),
                Tab(text: "Contact Help"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTicketsListTab(state),
                  _buildContactTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E4D2B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment),
        label: const Text("New Ticket"),
        onPressed: () {
          _showCreateTicketDialog(context, state);
        },
      ),
    );
  }

  Widget _buildTicketsListTab(AppState state) {
    if (state.tickets.isEmpty) {
      return const Center(child: Text("No support tickets created yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.tickets.length,
      itemBuilder: (context, idx) {
        final t = state.tickets[idx];
        final bool isOpen = t.status.toLowerCase() == 'open';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOpen ? Colors.orange : Colors.green).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.status.toUpperCase(),
                    style: TextStyle(
                      color: isOpen ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(t.description ?? ''),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Priority: ${t.priority.toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                    ),
                    if (t.createdAt != null)
                      Text(
                        "${t.createdAt!.day}/${t.createdAt!.month}/${t.createdAt!.year}",
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Need Technical Support?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B)),
          ),
          const SizedBox(height: 8),
          const Text("Our network engineers are available to diagnose Modbus RTU / slave configuration issues offline or over-the-air."),
          const SizedBox(height: 36),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF1E4D2B)),
              title: const Text("Helpline Phone"),
              subtitle: const Text("+91 1800 123 4567 (Toll-Free)"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF1E4D2B)),
              title: const Text("Helpline Email"),
              subtitle: const Text("support@macsoftdrip.com"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Create Help Ticket"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Ticket Title"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description details"),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Priority: "),
                        const SizedBox(width: 8),
                        ...["low", "medium", "high"].map((p) {
                          bool isSel = _selectedPriority == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(p.toUpperCase()),
                              selected: isSel,
                              selectedColor: const Color(0xFF1E4D2B),
                              labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 11),
                              onSelected: (selected) {
                                if (selected) {
                                  setStateDialog(() {
                                    _selectedPriority = p;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
                _isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () async {
                          if (_titleController.text.isNotEmpty && _descController.text.isNotEmpty) {
                            setStateDialog(() => _isLoading = true);
                            
                            final success = await state.createTicket(
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              priority: _selectedPriority,
                            );

                            if (context.mounted) {
                              setStateDialog(() => _isLoading = false);
                              if (success) {
                                _titleController.clear();
                                _descController.clear();
                                Navigator.pop(c);
                              }
                            }
                          }
                        },
                        child: const Text("Create Ticket"),
                      ),
              ],
            );
          },
        );
      },
    );
  }
}
