import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/status_chip.dart';
import '../widgets/command_progress_tile.dart';

class CommandStatusScreen extends StatelessWidget {
  final String commandId;

  const CommandStatusScreen({
    super.key,
    required this.commandId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Progress'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          final cmd = state.activeCommand;
          if (cmd == null || cmd.id != commandId) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF2D7A3A)),
                  const SizedBox(height: 16),
                  const Text('No Active Command Running', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  )
                ],
              ),
            );
          }

          final isFinished = !cmd.isActive;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cmd.action.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            StatusChip(status: cmd.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Target: ${cmd.targetType.toUpperCase()} #${cmd.targetId}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF8A958A)),
                        ),
                        Text(
                          'Source: ${cmd.source.toUpperCase()} · Sent: ${cmd.createdAt.toString().substring(11, 19)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8A958A)),
                        ),
                        if (cmd.failedReason != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cmd.failedReason!,
                                    style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Loader or Completed state
                if (!isFinished) ...[
                  const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Color(0xFF2D7A3A))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Polling master controller status...',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF8A958A)),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Icon(
                      cmd.status == 'acknowledged' || cmd.status == 'partialSuccess' ? Icons.check_circle_rounded : Icons.cancel,
                      color: cmd.status == 'acknowledged' || cmd.status == 'partialSuccess' ? const Color(0xFF2D7A3A) : const Color(0xFFDC2626),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      cmd.status == 'acknowledged' || cmd.status == 'partialSuccess' ? 'Command Executed Successfully' : 'Command Execution Failed',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Commands item list (for zones)
                if (cmd.commandItems.isNotEmpty) ...[
                  const Text(
                    'Valve Command Statuses',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2A1F)),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cmd.commandItems.length,
                      itemBuilder: (context, i) {
                        final item = cmd.commandItems[i];
                        return CommandProgressTile(item: item);
                      },
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                ],

                // Action to dismiss
                if (isFinished)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Dismiss'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
