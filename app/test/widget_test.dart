import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/main.dart';
import 'package:app/services/app_state.dart';

void main() {
  testWidgets('shows login screen when unauthenticated', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('DripFlow'), findsOneWidget);
    expect(find.text('Welcome, Farmer!'), findsOneWidget);
  });
}
