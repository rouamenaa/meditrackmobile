import 'package:meditrackmobile/database/database_helper.dart';
import '../../auth/services/session.dart';
import '../models/physical_activity.dart';

/// Synthèse hebdomadaire des activités physiques du patient
class ActivityWeeklySummary {
  final int totalMinutes;
  final int totalCalories;
  final double totalDistanceKm;
  final int sessionCount;
  final int weeklyGoalMinutes; // Recommandation OMS : 150 minutes / semaine

  const ActivityWeeklySummary({
    required this.totalMinutes,
    required this.totalCalories,
    required this.totalDistanceKm,
    required this.sessionCount,
    this.weeklyGoalMinutes = 150,
  });

  /// Progression vers l'objectif (0.0 à 1.0)
  double get goalProgress =>
      weeklyGoalMinutes > 0 ? (totalMinutes / weeklyGoalMinutes).clamp(0.0, 1.0) : 0.0;

  /// true si l'objectif hebdomadaire est atteint
  bool get goalAchieved => totalMinutes >= weeklyGoalMinutes;
}

class ActivityService {
  final DatabaseHelper _dbHelper;

  ActivityService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const String tableName = 'physical_activities';

  /// Résout l'identifiant utilisateur effectif (argument explicite ou session active)
  String? _resolveUserId(String? userId) =>
      userId ?? Session.instance.user?.id;

  /// CREATE : Insère une nouvelle activité physique et retourne l'activité avec son id généré
  Future<PhysicalActivity> create(PhysicalActivity activity) async {
    final db = await _dbHelper.database;
    final map = activity.toMap()..remove('id');
    
    // Si l'activité n'a pas de userId, on tente d'associer la session en cours
    if (map['user_id'] == null) {
      final currentUserId = Session.instance.user?.id;
      if (currentUserId != null) {
        map['user_id'] = currentUserId;
      }
    }

    final id = await db.insert(tableName, map);
    return activity.copyWith(
      id: id,
      userId: map['user_id']?.toString(),
    );
  }

  /// READ : Récupère la liste des activités triées par date décroissante
  /// Supporte le filtrage optionnel par utilisateur et par type de sport
  Future<List<PhysicalActivity>> getAll({
    String? userId,
    String? typeFilter,
  }) async {
    final db = await _dbHelper.database;
    final targetUserId = _resolveUserId(userId);

    final conditions = <String>[];
    final whereArgs = <dynamic>[];

    if (targetUserId != null) {
      conditions.add('(user_id = ? OR user_id IS NULL)');
      whereArgs.add(targetUserId);
    }

    if (typeFilter != null && typeFilter.trim().isNotEmpty && typeFilter != 'Tous') {
      conditions.add('LOWER(type) = LOWER(?)');
      whereArgs.add(typeFilter.trim());
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'datetime(activity_date) DESC, id DESC',
    );

    return maps.map((map) => PhysicalActivity.fromMap(map)).toList();
  }

  /// READ : Calcule le bilan des activités pour la semaine en cours (du lundi au dimanche)
  Future<ActivityWeeklySummary> getWeeklySummary({String? userId}) async {
    final db = await _dbHelper.database;
    final targetUserId = _resolveUserId(userId);

    final now = DateTime.now();
    // Début de la semaine courante (Lundi à 00:00:00)
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final mondayIso = monday.toIso8601String();

    final conditions = <String>['activity_date >= ?'];
    final whereArgs = <dynamic>[mondayIso];

    if (targetUserId != null) {
      conditions.add('(user_id = ? OR user_id IS NULL)');
      whereArgs.add(targetUserId);
    }

    final rows = await db.query(
      tableName,
      where: conditions.join(' AND '),
      whereArgs: whereArgs,
    );

    int totalMinutes = 0;
    int totalCalories = 0;
    double totalDistance = 0.0;

    for (final r in rows) {
      final act = PhysicalActivity.fromMap(r);
      totalMinutes += act.durationMinutes;
      if (act.caloriesBurned != null) {
        totalCalories += act.caloriesBurned!;
      }
      if (act.distanceKm != null) {
        totalDistance += act.distanceKm!;
      }
    }

    return ActivityWeeklySummary(
      totalMinutes: totalMinutes,
      totalCalories: totalCalories,
      totalDistanceKm: totalDistance,
      sessionCount: rows.length,
    );
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
      throw ArgumentError("Impossible de mettre à jour une activité sans identifiant (id)");
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
