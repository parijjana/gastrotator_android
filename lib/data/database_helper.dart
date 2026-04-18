import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/recipe.dart';

/// [SYSTEM INTEGRITY]: Data layer with Web-Safe Fallback.
/// Uses SQLite on native platforms and an In-Memory Mock on Web for UI testing.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-memory storage for Web/Testing fallback
  final Map<String, List<Map<String, dynamic>>> _webDb = {
    'recipes': [],
    'logs': [],
  };

  DatabaseHelper._init();

  static String _dbName = 'recipes.db';
  static void setTestMode({bool enabled = true}) {
    _dbName = enabled ? ':memory:' : 'recipes.db';
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database?> get database async {
    if (kIsWeb) return null; // Web uses _webDb directly via helper methods
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final String path;
    if (filePath == ':memory:') {
      path = inMemoryDatabasePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    return await openDatabase(
      path,
      version: 11,
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
        validation_result TEXT,
        queue_position INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        level TEXT NOT NULL,
        message TEXT NOT NULL,
        technical_details TEXT,
        context_id TEXT
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
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN thumbnail_url TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN calories_per_100g REAL');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN total_weight_grams REAL');
      } catch (e) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN cooking_time TEXT');
      } catch (e) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN flavor_profile TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN rating REAL');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN notes TEXT');
      } catch (e) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN transcript_error TEXT');
      } catch (e) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute(
          'ALTER TABLE recipes ADD COLUMN validation_result TEXT',
        );
      } catch (e) {}
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
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN queue_position INTEGER');
      } catch (e) {}
    }
    if (oldVersion < 11) {
      try {
        await db.execute('ALTER TABLE logs ADD COLUMN context_id TEXT');
      } catch (e) {}
    }
  }

  // --- Web-Safe Wrapper Methods ---

  Future<int> insertLog(Map<String, dynamic> log) async {
    if (kIsWeb) {
      final entry = Map<String, dynamic>.from(log);
      entry['id'] = _webDb['logs']!.length + 1;
      _webDb['logs']!.insert(0, entry);
      return entry['id'];
    }
    final db = await database;
    return await db!.insert('logs', log);
  }

  Future<List<Map<String, dynamic>>> getAllLogs() async {
    if (kIsWeb) return List.from(_webDb['logs']!);
    final db = await database;
    return await db!.query('logs', orderBy: 'id DESC');
  }

  Future<void> clearLogs() async {
    if (kIsWeb) {
      _webDb['logs']!.clear();
      return;
    }
    final db = await database;
    await db!.delete('logs');
  }

  Future<void> pruneLogs(int maxCount) async {
    if (kIsWeb) {
      if (_webDb['logs']!.length > maxCount) {
        _webDb['logs'] = _webDb['logs']!.sublist(0, maxCount);
      }
      return;
    }
    final db = await database;
    await db!.execute(
      '''
      DELETE FROM logs WHERE id IN (
        SELECT id FROM logs ORDER BY id DESC LIMIT -1 OFFSET ?
      )
    ''',
      [maxCount],
    );
  }

  Future<int> insert(Recipe recipe) async {
    if (kIsWeb) {
      final map = recipe.toMap();
      map['id'] = _webDb['recipes']!.length + 1;
      _webDb['recipes']!.insert(0, map);
      return map['id'];
    }
    final db = await database;
    return await db!.insert(
      'recipes',
      recipe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Recipe>> getAllRecipes() async {
    if (kIsWeb) {
      return _webDb['recipes']!.map((json) => Recipe.fromMap(json)).toList();
    }
    final db = await database;
    final result = await db!.query('recipes', orderBy: 'id DESC');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  Future<int> update(Recipe recipe) async {
    if (kIsWeb) {
      final idx = _webDb['recipes']!.indexWhere((r) => r['id'] == recipe.id);
      if (idx != -1) {
        _webDb['recipes']![idx] = recipe.toMap();
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db!.update(
      'recipes',
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<int> delete(int id) async {
    if (kIsWeb) {
      _webDb['recipes']!.removeWhere((r) => r['id'] == id);
      return 1;
    }
    final db = await database;
    return await db!.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    db?.close();
  }
}
