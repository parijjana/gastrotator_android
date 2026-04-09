import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/screens/import_recipe_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ImportRecipeScreen Widget Tests', () {
    testWidgets('Should show Search and URL fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImportRecipeScreen(),
          ),
        ),
      );

      expect(find.text('Import Recipe'), findsOneWidget);
      expect(find.text('Paste YouTube URL'), findsOneWidget);
      expect(find.text('Search YouTube'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Should handle URL submission', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImportRecipeScreen(),
          ),
        ),
      );

      // Trigger import
      await tester.enterText(find.byType(TextField).first, 'https://youtube.com/watch?v=abc');
      await tester.tap(find.byIcon(Icons.add_circle));
      
      // Verification: Ensure no immediate crashes
      await tester.pump();
      expect(find.byType(ImportRecipeScreen), findsOneWidget);
    });
  });
}
