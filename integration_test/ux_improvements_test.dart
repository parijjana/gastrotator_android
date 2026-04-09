import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UX Improvements Verification', () {
    testWidgets('Verify Search Clear Button and YouTube Fallback', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // 1. Check Clear Button
      await tester.enterText(searchField, 'Pizza');
      await tester.pumpAndSettle();
      
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget, reason: 'Clear button should appear when text is entered');

      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      expect(find.text('Pizza'), findsNothing, reason: 'Text should be cleared after tapping X');

      // 2. Check YouTube Fallback (Search for something non-existent)
      final uniqueQuery = 'UnlikelyRecipeNameXYZ123';
      await tester.enterText(searchField, uniqueQuery);
      await tester.pump(); // Start debounce
      await tester.pump(const Duration(seconds: 2)); // Wait for search
      await tester.pumpAndSettle();

      expect(find.text('SUGGESTIONS FROM YOUTUBE'), findsOneWidget, 
          reason: 'YouTube suggestions should appear if no local recipes match');
    });

    testWidgets('Verify API Key Guard on Import Screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Import
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      // Enter a URL and try to import (assuming no API key is set in a fresh run)
      final urlField = find.widgetWithText(TextField, 'https://youtube.com/watch?v=...');
      await tester.enterText(urlField, 'https://www.youtube.com/watch?v=3iNyUwPKrXQ');
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();

      expect(find.text('Gemini Key Missing'), findsOneWidget, 
          reason: 'Dialog should appear if importing without an API key');
      
      expect(find.text('Go to Settings'), findsOneWidget);
    });
  });
}
