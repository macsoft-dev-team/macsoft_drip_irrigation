import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  bool _applied = false;
  bool _showChat = false;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {"text": "Hello John! How can I help you troubleshoot your drip system today?", "isMe": false}
  ];

  void _sendMessage(String txt) {
    if (txt.trim().isEmpty) return;
    setState(() {
      _messages.add({"text": txt, "isMe": true});
    });
    _chatController.clear();

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        String resp = "Let me check the signal RSSI and Modbus registers.";
        final q = txt.toLowerCase();
        if (q.contains("moisture")) {
          resp = "North Farm is currently at 45% moisture. A 10-minute increase is recommended for optimal absorption.";
        } else if (q.contains("pressure")) {
          resp = "Standard pressure is 2.4 Bar. If it drops below 1.5, check for pipeline leakage or filter choking.";
        } else if (q.contains("offline")) {
          resp = "Slave boards go offline due to battery drain or distance. Check battery voltage is above 3.6V.";
        }

        setState(() {
          _messages.add({"text": resp, "isMe": false});
        });
        _scrollToBottom();
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🤖 Drip AI")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Drip AI Advice Card
            Card(
              color: const Color(0xFF1A1F36),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF00E676)),
                        SizedBox(width: 8),
                        Text(
                          "Today's Advice",
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _adviceSpecRow("Temperature", "31°C"),
                    _adviceSpecRow("Moisture", "43%"),
                    const Divider(color: Colors.white24, height: 24),
                    const Text(
                      "Recommendation",
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Increase morning irrigation by 10 minutes.",
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "Confidence: 92%",
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: _applied
                      ? Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text("Applied Successfully", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: const Color(0xFF2D7A3A),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            setState(() => _applied = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Irrigation recommendation applied.")),
                            );
                          },
                          child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                ),
                const SizedBox(width: 12),
                if (!_applied)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Recommendation ignored.")),
                        );
                      },
                      child: const Text("Ignore"),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),

            // 2. Chat trigger
            const Text(
              "Need help?",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D7A3A)),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2D7A3A)),
                title: const Text("Ask Drip AI Co-Pilot", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Ask about moisture thresholds or valves status"),
                trailing: Icon(_showChat ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                onTap: () {
                  setState(() {
                    _showChat = !_showChat;
                  });
                },
              ),
            ),

            if (_showChat) ...[
              const SizedBox(height: 12),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, idx) {
                          final m = _messages[idx];
                          final isMe = m['isMe'] == true;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF2D7A3A) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                m['text'] as String,
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: const InputDecoration(
                                hintText: "Type message...",
                                border: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF2D7A3A)),
                            onPressed: () => _sendMessage(_chatController.text),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _adviceSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
