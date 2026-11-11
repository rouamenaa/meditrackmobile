import 'package:meditrackmobile/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/physical_activity.dart';

class ActivityService {
  final DatabaseHelper _dbHelper;

  ActivityService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const String tableName = 'physical_activities';

  /// CREATE : Insère une nouvelle activité physique et retourne l'activité avec son id généré
  Future<PhysicalActivity> create(PhysicalActivity activity) async {
    final db = await _dbHelper.database;
    final map = activity.toMap()..remove('id');
    final id = await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return activity.copyWith(id: id);
  }

  /// READ : Récupère la liste des activités triées par date décroissante (plus récentes en premier)
  Future<List<PhysicalActivity>> getAll({int? userId}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps;

    if (userId != null) {
      maps = await db.query(
        tableName,
        where: 'user_id = ? OR user_id IS NULL',
        whereArgs: [userId],
        orderBy: 'datetime(activity_date) DESC, id DESC',
      );
    } else {
      maps = await db.query(
        tableName,
        orderBy: 'datetime(activity_date) DESC, id DESC',
      );
    }

    return maps.map((map) => PhysicalActivity.fromMap(map)).toList();
  }

  /// READ : Récupère une activité par son identifiant unique
  Future<PhysicalActivity?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PhysicalActivity.fromMap(maps.first);
  }

  /// UPDATE : Modifie une activité existante
  Future<int> update(PhysicalActivity activity) async {
    if (activity.id == null) {
      throw ArgumentError("Cannot update an activity without an identifier (id)");
    }
    final db = await _dbHelper.database;
    return await db.update(
      tableName,
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  /// DELETE : Supprime une activité par son identifiant
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
