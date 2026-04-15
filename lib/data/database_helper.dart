import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/recipe.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dish_name TEXT NOT NULL,
        category TEXT,
        ingredients TEXT,
        recipe TEXT,
        youtube_url TEXT,
        youtube_title TEXT,
        youtube_channel TEXT,
        thumbnail_url TEXT,
        total_calories REAL,
        calories_per_100g REAL,
        total_weight_grams REAL,
        cooking_time TEXT,
        transcript TEXT,
        import_status TEXT,
        flavor_profile TEXT,
        rating REAL,
        notes TEXT,
        transcript_error TEXT,
        validation_result TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        level TEXT NOT NULL,
        message TEXT NOT NULL,
        technical_details TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE recipes ADD COLUMN total_calories REAL');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE recipes ADD COLUMN transcript TEXT');
      await db.execute('ALTER TABLE recipes ADD COLUMN import_status TEXT');
    }
    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE recipes ADD COLUMN thumbnail_url TEXT'); } catch(e) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN calories_per_100g REAL'); } catch(e) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN total_weight_grams REAL'); } catch(e) {}
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE recipes ADD COLUMN cooking_time TEXT'); } catch(e) {}
    }
    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE recipes ADD COLUMN flavor_profile TEXT'); } catch(e) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN rating REAL'); } catch(e) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN notes TEXT'); } catch(e) {}
    }
    if (oldVersion < 7) {
      try { await db.execute('ALTER TABLE recipes ADD COLUMN transcript_error TEXT'); } catch(e) {}
    }
    if (oldVersion < 8) {
      try { await db.execute('ALTER TABLE recipes ADD COLUMN validation_result TEXT'); } catch(e) {}
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT NOT NULL,
          level TEXT NOT NULL,
          message TEXT NOT NULL,
          technical_details TEXT
        )
      ''');
    }
  }

  // Log methods
  Future<int> insertLog(Map<String, dynamic> log) async {
    final db = await instance.database;
    return await db.insert('logs', log);
  }

  Future<List<Map<String, dynamic>>> getAllLogs() async {
    final db = await instance.database;
    return await db.query('logs', orderBy: 'id DESC');
  }

  Future<void> clearLogs() async {
    final db = await instance.database;
    await db.delete('logs');
  }

  Future<void> pruneLogs(int maxCount) async {
    final db = await instance.database;
    await db.execute('''
      DELETE FROM logs WHERE id IN (
        SELECT id FROM logs ORDER BY id DESC LIMIT -1 OFFSET ?
      )
    ''', [maxCount]);
  }

  Future<int> insert(Recipe recipe) async {
    final db = await instance.database;
    return await db.insert('recipes', recipe.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await instance.database;
    final result = await db.query('recipes', orderBy: 'id DESC');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<int> update(Recipe recipe) async {
    final db = await instance.database;
    return db.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
