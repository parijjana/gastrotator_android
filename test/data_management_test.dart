import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:android_app/data/database_helper.dart';
import 'package:android_app/models/recipe.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Import/Export Data Logic Tests', () {
    late String dbPath;
    late String exportPath;

    setUp(() async {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, 'recipes.db');
      exportPath = p.join(databasesPath, 'test_export.zip');

      // Clear any existing test data
      final dbFile = File(dbPath);
      if (await dbFile.exists()) await dbFile.delete();
      final expFile = File(exportPath);
      if (await expFile.exists()) await expFile.delete();
    });

    test('Full Export and Import Cycle', () async {
      final dbHelper = DatabaseHelper.instance;

      // 1. Add some dummy data
      final testRecipe = Recipe(
        dishName: "Export Test Dish",
        category: "Test",
        ingredients: "Ingredient 1\nIngredient 2",
        recipe: "Step 1\nStep 2",
        youtubeUrl: "https://youtube.com/test",
        importStatus: "Completed",
      );
      await dbHelper.insert(testRecipe);

      final initialRecipes = await dbHelper.getAllRecipes();
      expect(initialRecipes.length, 1);
      expect(initialRecipes.first.dishName, "Export Test Dish");

      // 2. Perform Export (Manual Logic)
      final dbFile = File(dbPath);
      expect(await dbFile.exists(), isTrue);

      final archive = Archive();
      final bytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('recipes.db', bytes.length, bytes));
      final zipData = ZipEncoder().encode(archive);

      final outFile = File(exportPath);
      await outFile.writeAsBytes(zipData);
      expect(await outFile.exists(), isTrue);

      // 3. Clear Database
      // Close the connection first to allow deletion
      // (DatabaseHelper doesn't expose a way to reset easily, so we just delete the file)
      // Actually, DatabaseHelper uses a singleton _database.
      // We'll just delete and re-init if we can, but simpler is to just delete records.
      final db = await dbHelper.database;
      await db?.delete('recipes');

      var currentRecipes = await dbHelper.getAllRecipes();
      expect(currentRecipes.isEmpty, isTrue);

      // 4. Perform Import (Manual Logic)
      final importedFile = File(exportPath);
      final importBytes = await importedFile.readAsBytes();
      final decodedArchive = ZipDecoder().decodeBytes(importBytes);

      bool found = false;
      for (final file in decodedArchive) {
        if (file.isFile && file.name == 'recipes.db') {
          final data = file.content as List<int>;
          await File(dbPath).writeAsBytes(data, flush: true);
          found = true;
          break;
        }
      }
      expect(found, isTrue);

      // 5. Verify Data Restored
      // We might need to reopen the DB or it might just work if sqflite handles it
      final restoredRecipes = await dbHelper.getAllRecipes();
      expect(restoredRecipes.length, 1);
      expect(restoredRecipes.first.dishName, "Export Test Dish");
    });
  });
}
