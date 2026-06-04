import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_device.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';

class CommandPage extends StatefulWidget {
  final ApiDevice device;
  const CommandPage({super.key, required this.device});

  @override
  State<CommandPage> createState() => _CommandPageState();
}

class _CommandPageState extends State<CommandPage> {
  final _jsonCtrl = TextEditingController(text: '{}');
  String _template = 'start'; // start | stop | custom
  List<DeviceCommand> _history = [];
  bool _histLoading = false;
  bool _sending = false;
  String? _sendError;

  static const _templates = {
    'start': {'PWR': 1},
    'stop': {'PWR': 0},
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _jsonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final token = context.read<AppState>().token;
    if (token == null) return;
    setState(() => _histLoading = true);
    try {
      final api = ApiService(token: token);
      final list = await api.getCommands(widget.device.id);
      if (!mounted) return;
      setState(() { _history = list; _histLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _histLoading = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    if (_template == 'custom') {
      try {
        return jsonDecode(_jsonCtrl.text) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Invalid JSON payload');
      }
    }
    return _templates[_template]!;
  }

  Future<void> _send() async {
    final token = context.read<AppState>().token;
    if (token == null) return;
    Map<String, dynamic> payload;
    try {
      payload = _buildPayload();
    } catch (e) {
      setState(() => _sendError = e.toString());
      return;
    }
    setState(() { _sending = true; _sendError = null; });
    try {
      final api = ApiService(token: token);
      final cmd = await api.sendCommand(widget.device.id, payload);
      if (!mounted) return;
      setState(() {
        _history.insert(0, cmd);
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Command sent'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _sendError = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1F36)), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.device.name ?? widget.device.imeinumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
          Text('Command Console', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ]),
      ),
      body: Column(children: [
        // ── Send panel ──────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Send Command', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
            const SizedBox(height: 12),
            Row(children: [
              _TemplateBtn(label: 'START', iconColor: const Color(0xFF10B981), selected: _template == 'start', onTap: () => setState(() { _template = 'start'; _jsonCtrl.text = jsonEncode(_templates['start']); })),
              const SizedBox(width: 8),
              _TemplateBtn(label: 'STOP', iconColor: const Color(0xFFEF4444), selected: _template == 'stop', onTap: () => setState(() { _template = 'stop'; _jsonCtrl.text = jsonEncode(_templates['stop']); })),
              const SizedBox(width: 8),
              _TemplateBtn(label: 'Custom', iconColor: const Color(0xFF6D28D9), selected: _template == 'custom', onTap: () => setState(() { _template = 'custom'; _jsonCtrl.text = '{}'; })),
            ]),
            if (_template == 'custom') ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: TextField(
                  controller: _jsonCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: '{"key": "value"}',
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  jsonEncode(_templates[_template]),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF374151)),
                ),
              ),
            ],
            if (_sendError != null) ...[
              const SizedBox(height: 8),
              Text(_sendError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 16),
                label: Text(_sending ? 'Sending…' : 'Send Command'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2D7A3A), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _sending ? null : _send,
              ),
            ),
          ]),
        ),
        // ── History ─────────────────────────────────────────
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                const Text('Command History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
                const Spacer(),
                if (_histLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else IconButton(icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6B7280)), onPressed: _loadHistory, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
            ),
            Expanded(
              child: _history.isEmpty && !_histLoading
                  ? const Center(child: Text('No commands sent yet', style: TextStyle(color: Color(0xFF9CA3AF))))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: _history.length,
                      itemBuilder: (_, i) => _CommandTile(cmd: _history[i]),
                    ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TemplateBtn extends StatelessWidget {
  final String label;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;
  const _TemplateBtn({required this.label, required this.iconColor, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? iconColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? iconColor : const Color(0xFFE2E8F0), width: selected ? 2 : 1),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? iconColor : const Color(0xFF6B7280)))),
        ),
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  final DeviceCommand cmd;
  const _CommandTile({required this.cmd});

  static String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final (bg, text, label) = switch (cmd.status) {
      'ACK' => (const Color(0xFFECFDF5), const Color(0xFF10B981), 'ACK'),
      'SENT' => (const Color(0xFFE8F5E9), const Color(0xFF2D7A3A), 'SENT'),
      'FAILED' => (const Color(0xFFFEF2F2), const Color(0xFFEF4444), 'FAILED'),
      _ => (const Color(0xFFF8FAFC), const Color(0xFF6B7280), 'PENDING'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(jsonEncode(cmd.payload), style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF374151))),
          const SizedBox(height: 4),
          Text(_fmt(cmd.createdAt), style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: text.withValues(alpha: 0.3))),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: text)),
        ),
      ]),
    );
  }
}
