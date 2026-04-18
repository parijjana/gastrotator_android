import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UI Regression: Paste URL behavior', () {
    testWidgets(
      'Pasting a URL in HomeScreen search should trigger Magic Import',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Find search field
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        // Simulate pasting a URL
        await tester.enterText(
          searchField,
          'https://youtube.com/watch?v=browser-magic',
        );

        // Wait for auto-trigger logic
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verify that the Snackbar appears (indicating logic triggered)
        expect(find.text('AI Magic extraction started!'), findsOneWidget);
      },
    );

    testWidgets('Direct URL in ImportScreen should trigger Magic Import', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Import Screen
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      // Find URL field (first TextField on this screen)
      final urlField = find.byType(TextField).first;

      // Simulate typing/pasting
      await tester.enterText(
        urlField,
        'https://youtube.com/watch?v=import-magic',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should show snackbar and pop back to home
      expect(
        find.text('AI Magic extraction started! Check Home.'),
        findsOneWidget,
      );
    });
  });
}
