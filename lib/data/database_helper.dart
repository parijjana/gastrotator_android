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
      version: 6, // Increment version for V2 fields
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
        notes TEXT
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
