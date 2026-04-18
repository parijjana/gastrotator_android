import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('GastRotator smoke test - Verify initial empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GastRotatorApp()));
    await tester.pumpAndSettle();

    expect(find.text('GastRotator'), findsOneWidget);

    // Verify instructional empty state
    expect(find.text('1. FIND A RECIPE'), findsOneWidget);
    expect(find.text('2. SEARCH, PASTE, OR SHARE'), findsOneWidget);

    // Verify Bottom Navigation exists
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    // Verify FAB is GONE (Unified Search Pill used instead)
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
