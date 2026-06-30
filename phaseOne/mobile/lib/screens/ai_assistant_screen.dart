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
  int _aiSubTab = 0; // 0 = AI Home, 1 = Leaf Scanner, 2 = Ask AI Chat
  final _chatInputController = TextEditingController();
  final _scrollController = ScrollController();

  // Leaf Scan States
  bool _isScanning = false;
  String? _leafDiagnosis;
  String? _leafRecommendation;

  // Chat message model
  final List<Map<String, dynamic>> _chatMessages = [
    {"text": "Hello John! I am your Drip AI Assistant. Ask me anything about soil moisture, tank levels, or controller troubleshooting.", "isMe": false},
  ];

  void _runLeafScan() {
    setState(() {
      _isScanning = true;
      _leafDiagnosis = null;
      _leafRecommendation = null;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _leafDiagnosis = "Tomato Leaf Mold (Passalora fulva)";
          _leafRecommendation = "Action Plan:\n• Apply copper-based organic fungicide.\n• Prune lower infected leaf layers to enhance airflow.\n• Avoid overhead leaf sprinkler watering; stick to drip line irrigation.";
        });
      }
    });
  }

  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add({"text": text, "isMe": true});
    });
    _chatInputController.clear();
    _scrollToBottom();

    // Answer delay simulation
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        String answer = "I'm checking the parameters of your master controller. ";
        final query = text.toLowerCase();
        if (query.contains("moisture") || query.contains("soil")) {
          answer = "Your soil moisture sensor registers 46% inside North Farm. For Tomatoes, the threshold should be at 55%. I suggest enabling a 15-minute manual drip run.";
        } else if (query.contains("water") || query.contains("today")) {
          answer = "According to flow meters, you have used 1,200 Liters of water today across all active blocks.";
        } else if (query.contains("valve") || query.contains("failure")) {
          answer = "For valve connection failures, verify that the 24VAC solenoid coils have correct resistance (20-60 ohms) and that the Slave ESP32 signal strength is stable.";
        } else if (query.contains("hello") || query.contains("hi")) {
          answer = "Hello John! Let me know if you want to run quick irrigation, check soil moisture, or view today's schedules.";
        } else {
          answer = "Understood. I recommend keeping the master controller online to receive telemetry logs. Let me know if you would like me to trigger a valve open command.";
        }

        setState(() {
          _chatMessages.add({"text": answer, "isMe": false});
        });
        _scrollToBottom();
      }
    });
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubTabButton(0, "AI Home", Icons.auto_awesome),
              _buildSubTabButton(1, "Leaf Scan", Icons.center_focus_strong),
              _buildSubTabButton(2, "Ask AI", Icons.chat_bubble_outline),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSubTabButton(int idx, String text, IconData icon) {
    final bool isSel = _aiSubTab == idx;
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: isSel ? const Color(0xFF1E4D2B) : Colors.grey),
      icon: Icon(icon, size: 18),
      label: Text(text, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      onPressed: () => setState(() => _aiSubTab = idx),
    );
  }

  Widget _buildBody() {
    switch (_aiSubTab) {
      case 0:
        return _buildAiHome();
      case 1:
        return _buildLeafScan();
      case 2:
        return _buildChat();
      default:
        return Container();
    }
  }

  Widget _buildAiHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Today's Diagnosis Recommendation",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B)),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1A1F36),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.eco, color: Color(0xFF00E676)),
                      SizedBox(width: 8),
                      Text("Tomato Crop Target", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "High Leaf Dampness & Lower Soil moisture",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Recommendation: Execute a 10 minute drip run in the morning to increase root saturation without wet foliage.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.amber, size: 18),
                          SizedBox(width: 4),
                          Text("Confidence: 92%", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: const Color(0xFF1E4D2B),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("AI Recommendation Applied!")),
                          );
                        },
                        child: const Text("Apply Recommendation"),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Quick Options", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => setState(() => _aiSubTab = 1),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.center_focus_strong, color: Color(0xFF1E4D2B), size: 32),
                          SizedBox(height: 12),
                          Text("Crop Diagnosis", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Diagnose via leaf camera scans", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => setState(() => _aiSubTab = 2),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Color(0xFF1E4D2B), size: 32),
                          SizedBox(height: 12),
                          Text("Ask chatbot AI", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Solve telemetry & valve issues", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLeafScan() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "AI Leaf Health Diagnostics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E4D2B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text("Upload a picture of a leaf to inspect crop diseases.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: _isScanning
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1E4D2B)),
                          const SizedBox(height: 16),
                          Text("Analyzing Leaf Image...", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : _leafDiagnosis != null
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
                              const SizedBox(height: 16),
                              Text(
                                "Diagnosis: $_leafDiagnosis",
                                style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _leafRecommendation!,
                                style: const TextStyle(fontSize: 14, color: Colors.black70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text("No Leaf Scanned Yet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text("UPLOAD LOG"),
                  onPressed: _runLeafScan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("CAMERA SCAN"),
                  onPressed: _runLeafScan,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, idx) {
              final m = _chatMessages[idx];
              final bool isMe = m['isMe'] == true;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF1E4D2B) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
                  ),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSuggestChip("Is soil moisture 46% good?"),
                _buildSuggestChip("How much water did I use today?"),
                _buildSuggestChip("Troubleshoot active valve error"),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    decoration: const InputDecoration(
                      hintText: "Ask AI Crop Assistant...",
                      border: InputBorder.none,
                      filled: false,
                    ),
                    onSubmitted: (v) => _sendChatMessage(v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF1E4D2B)),
                  onPressed: () => _sendChatMessage(_chatInputController.text),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSuggestChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () => _sendChatMessage(text),
      ),
    );
  }
}
