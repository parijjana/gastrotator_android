import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize sqflite for ffi
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('GastRotator smoke test - Verify initial empty state', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: GastRotatorApp()));

    // Verify that our app starts on the home screen
    expect(find.text('GastRotator'), findsOneWidget);
    
    // Verify initial "empty" message
    expect(find.text('Your kitchen is empty!'), findsOneWidget);

    // Verify FAB exists
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
