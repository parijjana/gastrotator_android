import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Test', () {
    testWidgets('Verify FAB navigates to Import Screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify Home Screen
      expect(find.text('GastRotator'), findsOneWidget);

      // 2. Tap FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // 3. Verify Import Screen
      expect(find.text('Import Recipe'), findsOneWidget);
      print("Success: FAB navigation verified!");
    });

    testWidgets('Verify Settings and About navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Tap Settings Icon from Home
      final settingsBtn = find.byIcon(Icons.settings_outlined);
      expect(settingsBtn, findsOneWidget);
      await tester.tap(settingsBtn);
      await tester.pumpAndSettle();

      // 2. Verify Settings Screen
      expect(find.text('Settings'), findsOneWidget);
      
      // 3. Navigate to About from Settings
      final aboutTile = find.text('About GastRotator Fresh');
      await tester.scrollUntilVisible(
        aboutTile, 
        500.0,
        scrollable: find.byType(Scrollable).last,
      );
      expect(aboutTile, findsOneWidget);
      await tester.tap(aboutTile);
      await tester.pumpAndSettle();
      
      // 4. Verify About Screen
      expect(find.text('About'), findsOneWidget);
      print("Success: Settings and About navigation verified!");
    });
  });
}
