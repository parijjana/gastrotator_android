import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/data/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.setTestMode(enabled: true);
  });

  group('DatabaseHelper Maintenance Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      await db?.delete('logs');
    });

    test('pruneLogs should keep newest entries and delete oldest', () async {
      // 1. Insert 10 logs
      for (int i = 1; i <= 10; i++) {
        await dbHelper.insertLog({
          'timestamp': DateTime.now().toIso8601String(),
          'level': 'INFO',
          'message': 'Log $i',
        });
      }

      final allLogsBefore = await dbHelper.getAllLogs();
      expect(allLogsBefore.length, 10);

      // 2. Prune to 5
      await dbHelper.pruneLogs(5);

      final allLogsAfter = await dbHelper.getAllLogs();
      expect(allLogsAfter.length, 5);
      
      // 3. Verify they are the LATEST 5 (highest IDs)
      // Note: getAllLogs returns DESC order (newest first)
      expect(allLogsAfter.first['message'], 'Log 10');
      expect(allLogsAfter.last['message'], 'Log 6');
    });

    test('clearLogs should remove all entries', () async {
      await dbHelper.insertLog({
        'timestamp': DateTime.now().toIso8601String(),
        'level': 'INFO',
        'message': 'Test Log',
      });
      
      await dbHelper.clearLogs();
      final logs = await dbHelper.getAllLogs();
      expect(logs, isEmpty);
    });
  });
}
