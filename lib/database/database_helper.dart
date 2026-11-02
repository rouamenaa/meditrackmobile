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
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createUserCache(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // v1/v2 : les comptes étaient locaux, ils sont maintenant sur le serveur
          await db.execute('DROP TABLE IF EXISTS medecins');
          await db.execute('DROP TABLE IF EXISTS users');
          await _createUserCache(db);
        }
      },
    );
  }

  Future<void> _createUserCache(Database db) async {
    await db.execute('''
      CREATE TABLE user_cache (
        id TEXT PRIMARY KEY,
        json TEXT NOT NULL
      )
    ''');
  }
}