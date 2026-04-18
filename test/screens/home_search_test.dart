import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_app/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:android_app/data/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setTestMode(enabled: true);
  });

  testWidgets('Search Results should be visible even when Kitchen is empty', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GastRotatorApp()));
    await tester.pumpAndSettle();

    // 1. Verify empty state is visible initially
    expect(find.text('1. FIND A RECIPE'), findsOneWidget);

    // 2. Enter a search query
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Pizza');
    await tester.pumpAndSettle();

    // 3. Verify empty state is HIDDEN
    expect(find.text('1. FIND A RECIPE'), findsNothing);

    // 4. Verify "No recipes found in your collection" or results header is visible
    expect(find.text('ONLINE SUGGESTIONS'), findsOneWidget);
  });
}
