import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/field_card.dart';
import 'field_details_screen.dart';

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final fields = state.fields;

    return Scaffold(
      appBar: AppBar(title: const Text("Fields / Farms")),
      body: RefreshIndicator(
        onRefresh: () async {
          await state.loadFields();
        },
        child: fields.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.landscape_rounded, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text("No fields configured.", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => state.loadFields(),
                      child: const Text("REFRESH"),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: fields.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final f = fields[idx];
                  return FieldCard(
                    field: f,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => FieldDetailScreen(fieldId: f.id),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

