import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Import Workflow Emulator Test', () {
    testWidgets('Verify manual URL import flow and error handling', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Navigate to Import Screen
      final fab = find.byIcon(Icons.auto_awesome);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // 2. Verify we are on Import screen
      expect(find.text('Import Recipe'), findsOneWidget);

      // 3. Enter the video that was previously failing
      final urlField = find.byType(TextField).first;
      await tester.enterText(urlField, 'https://www.youtube.com/watch?v=3iNyUwPKrXQ');
      await tester.pumpAndSettle();

      // 4. Tap Magic Import (now add_circle icon)
      final importButton = find.byIcon(Icons.add_circle);
      await tester.tap(importButton);
      await tester.pumpAndSettle(); // Navigate back to home
      
      // 5. Wait for the status to change to "AI Processing..."
      bool success = false;
      String lastStatus = "None";
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
        final statusFinder = find.textContaining('Status:');
        if (statusFinder.evaluate().isNotEmpty) {
          final statusText = (tester.widget<Text>(statusFinder).data ?? "");
          lastStatus = statusText;
          print("DEBUG: Current Status in Emulator: $statusText");
          if (statusText.contains('AI Processing...') || 
              statusText.contains('Completed') || 
              statusText.contains('Failed: Missing API Key')) {
            success = true;
            break;
          }
        }
        
        // If we see an error dialog, fail immediately
        if (find.text('Import Failed').evaluate().isNotEmpty) {
          final errorText = tester.widget<Text>(find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Text),
          ).last).data;
          fail('Import Failed with error: $errorText');
        }
      }
      
      expect(success, isTrue, reason: 'Should have reached AI phase. Last seen status: $lastStatus');
      print("Success: Verified transcript extraction in Emulator environment!");
    });
  });
}
