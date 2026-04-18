import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Test', () {
    testWidgets('Verify Bottom Navigation: Kitchen, Settings, About', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify Home Screen (Kitchen)
      expect(find.text('GastRotator'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);

      // 2. Tap Settings Tab
      final settingsTab = find.text('Settings');
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab);
      await tester.pumpAndSettle();

      // 3. Verify Settings Screen
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Gemini API Key'), findsOneWidget);

      // 4. Tap About Tab
      final aboutTab = find.text('About');
      expect(aboutTab, findsOneWidget);
      await tester.tap(aboutTab);
      await tester.pumpAndSettle();

      // 5. Verify About Screen
      expect(find.text('About'), findsOneWidget);
      expect(find.text('GastRotator'), findsWidgets); // Title and version text
    });
  });
}
