import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/support_ticket.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_loading_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/status_chip.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Help banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7A3A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Submit a ticket or call us directly. Our agents are available 24/7.',
                  style: TextStyle(color: Color(0xFFE8F5E9), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SupportActionCard(
            title: 'Create Support Ticket',
            description: 'Report issues regarding controllers, valves, or scheduling.',
            icon: Icons.add_comment_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportTicketFormScreen()),
              );
            },
          ),
          _SupportActionCard(
            title: 'My Support Tickets',
            description: 'View active and resolved support tickets.',
            icon: Icons.forum_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportTicketListScreen()),
              );
            },
          ),
          _SupportActionCard(
            title: 'Call Support Hotline',
            description: 'Direct phone line to our support centre.',
            icon: Icons.phone_in_talk_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling hotline support: 1800-123-4567')),
              );
            },
          ),
          _SupportActionCard(
            title: 'WhatsApp Support',
            description: 'Chat with our technician team instantly.',
            icon: Icons.chat_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening WhatsApp Support Chat placeholder.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SupportTicketFormScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialMCId;
  final String? initialValveId;

  const SupportTicketFormScreen({
    super.key,
    this.initialTitle,
    this.initialMCId,
    this.initialValveId,
  });

  @override
  State<SupportTicketFormScreen> createState() => _SupportTicketFormScreenState();
}

class _SupportTicketFormScreenState extends State<SupportTicketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  String _priority = 'medium'; // low, medium, high, critical
  String? _selectedFieldId;
  String? _selectedMCId;
  String? _selectedValveId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descController = TextEditingController();
    _selectedMCId = widget.initialMCId;
    _selectedValveId = widget.initialValveId;

    final state = context.read<AppState>();
    if (state.fields.isNotEmpty) {
      _selectedFieldId = state.fields[0].id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final ok = await context.read<AppState>().createTicket(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          priority: _priority,
          fieldId: _selectedFieldId,
          masterControllerId: _selectedMCId,
          valveId: _selectedValveId,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket created successfully.'), backgroundColor: Color(0xFF2D7A3A)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ticket'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Issue Title',
                hint: 'e.g. Solenoid valve #2 not responding',
                controller: _titleController,
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Describe the issue',
                hint: 'Provide full details about what is not working.',
                controller: _descController,
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              const Text('Priority Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 16),

              const Text('Related Field (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8A958A))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedFieldId,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                items: state.fields.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                onChanged: (val) => setState(() => _selectedFieldId = val),
              ),
              const SizedBox(height: 24),

              // Attachment placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: Color(0xFF8A958A)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload Image / Attachment (Optional)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              AppLoadingButton(
                label: 'Submit Ticket',
                isLoading: _isLoading,
                onPressed: _submitTicket,
                color: const Color(0xFF2D7A3A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportTicketListScreen extends StatefulWidget {
  const SupportTicketListScreen({super.key});

  @override
  State<SupportTicketListScreen> createState() => _SupportTicketListScreenState();
}

class _SupportTicketListScreenState extends State<SupportTicketListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.ticketsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.tickets.isEmpty) {
            return const EmptyState(
              icon: Icons.speaker_notes_off_outlined,
              title: 'No Tickets Found',
              description: 'You have not submitted any support tickets yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => state.loadTickets(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.tickets.length,
              itemBuilder: (context, i) {
                final SupportTicket ticket = state.tickets[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SupportTicketDetailScreen(ticketId: ticket.id),
                        ),
                      );
                    },
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ticket.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusChip(status: ticket.status),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Priority: ${ticket.priority.toUpperCase()} · ${ticket.createdAt.toString().substring(0, 10)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8A958A)),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCBD5E1)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SupportTicketDetailScreen extends StatelessWidget {
  final String ticketId;
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final idx = state.tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return const Scaffold(body: Center(child: Text('Ticket not found')));
    final SupportTicket ticket = state.tickets[idx];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ticket.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E2A1F)),
                  ),
                ),
                StatusChip(status: ticket.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Priority: ${ticket.priority.toUpperCase()} · Created: ${ticket.createdAt.toLocal().toString().substring(0, 16)}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A))),
            const Divider(height: 32),

            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text(
              ticket.description ?? 'No description provided.',
              style: const TextStyle(color: Color(0xFF546E7A), fontSize: 14, height: 1.4),
            ),
            const Divider(height: 32),

            // Technician assignment details
            const Text('Assigned Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: Color(0xFF2D7A3A)),
                ),
                title: const Text('Ramesh Kumar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Lead Support Engineer · Status: Assigned'),
              ),
            ),
            const SizedBox(height: 24),

            // Message Board Placeholder
            const Text('Conversation & Messages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technician (Ramesh Kumar):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2D7A3A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hello, I am looking into your ticket now. I will check the MQTT logs for your solenoid valves and report back shortly.',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Just now',
                    style: TextStyle(fontSize: 10, color: Color(0xFF8A958A)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _SupportActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D7A3A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF2D7A3A), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E2A1F)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8A958A)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}
