import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'meditrack.db');
    return openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createUserCache(db);
        await _createPhysicalActivities(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // v1/v2 : les comptes étaient locaux, ils sont maintenant sur le serveur
          await db.execute('DROP TABLE IF EXISTS medecins');
          await db.execute('DROP TABLE IF EXISTS users');
          await _createUserCache(db);
        }
        if (oldVersion < 5) {
          // Recrée la table physical_activities pour supprimer l'ancienne contrainte FK vers `users`
          await db.execute('DROP TABLE IF EXISTS physical_activities');
          await _createPhysicalActivities(db);
        }
      },
    );
  }

  Future<void> _createUserCache(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_cache (
        id TEXT PRIMARY KEY,
        json TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPhysicalActivities(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS physical_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        type TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        distance_km REAL,
        intensity TEXT NOT NULL,
        activity_date TEXT NOT NULL,
        notes TEXT,
        calories_burned INTEGER
      )
    ''');
  }
}
