import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('Verify home screen and settings navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify that we are on the home screen
      expect(find.text('GastRotator'), findsOneWidget);
      expect(find.text('FIND A RECIPE'), findsOneWidget);

      // Navigate to settings via Bottom Nav
      final settingsTab = find.text('Settings');
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab);
      await tester.pumpAndSettle();

      // Verify settings screen
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Gemini API Key'), findsOneWidget);
      expect(find.text('Backup & Restore'), findsOneWidget);

      // Go back to home
      final homeTab = find.text('Kitchen');
      expect(homeTab, findsOneWidget);
      await tester.tap(homeTab);
      await tester.pumpAndSettle();

      // Verify we are back on home screen
      expect(find.text('GastRotator'), findsOneWidget);
    });
  });
}
