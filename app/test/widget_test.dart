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

    expect(find.text('System Login'), findsOneWidget);
    expect(find.text('Initialize'), findsOneWidget);
  });
}
