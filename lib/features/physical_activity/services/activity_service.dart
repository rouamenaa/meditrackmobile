import 'package:flutter/foundation.dart';
import 'package:meditrackmobile/database/database_helper.dart';
import '../../auth/services/api_service.dart';
import '../../auth/services/session.dart';
import '../models/physical_activity.dart';

/// Notificateur réactif pour les modifications des activités physiques dans SQLite
class ActivityChangeNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

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
  final ApiService _apiService;
  bool _isSyncing = false;

  /// Notificateur réactif global : notifie tous les écouteurs dès qu'une modification SQLite survient
  static final ActivityChangeNotifier changeNotifier = ActivityChangeNotifier();

  ActivityService({DatabaseHelper? dbHelper, ApiService? apiService})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _apiService = apiService ?? ApiService();

  static const String tableName = 'physical_activities';

  /// Résout l'identifiant utilisateur effectif (argument explicite ou session active)
  String? _resolveUserId(String? userId) =>
      userId ?? Session.instance.user?.id;

  /// CREATE : Insère une nouvelle activité physique en SQLite (offline-first)
  /// et la pousse vers MongoDB si connecté au réseau.
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

    int id;
    try {
      id = await db.insert(tableName, map);
    } catch (_) {
      try {
        await db.execute('ALTER TABLE physical_activities ADD COLUMN remote_id TEXT');
      } catch (_) {}
      id = await db.insert(tableName, map);
    }
    final created = activity.copyWith(
      id: id,
      userId: map['user_id']?.toString(),
    );

    // Notification réactive immédiate de l'interface
    changeNotifier.notify();

    // Synchronisation en arrière-plan vers MongoDB
    if (Session.instance.token != null) {
      _pushCreate(created);
    }

    return created;
  }

  /// Pousse la création vers le backend en tâche de fond
  Future<void> _pushCreate(PhysicalActivity act) async {
    try {
      final data = await _apiService.post('/activities', act.toJson());
      if (data is Map && data['id'] != null) {
        final remoteId = data['id'].toString();
        final db = await _dbHelper.database;
        await db.update(
          tableName,
          {'remote_id': remoteId},
          where: 'id = ?',
          whereArgs: [act.id],
        );
      }
    } catch (e) {
      debugPrint('[ActivityService] _pushCreate offline/failed: $e');
    }
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

    if (typeFilter != null &&
        typeFilter.trim().isNotEmpty &&
        typeFilter != 'Tous' &&
        typeFilter != 'All') {
      final tf = typeFilter.trim().toLowerCase();
      if (tf == 'walking' || tf == 'marche') {
        conditions.add('(LOWER(type) = ? OR LOWER(type) = ?)');
        whereArgs.addAll(['walking', 'marche']);
      } else if (tf == 'running' || tf == 'course') {
        conditions.add('(LOWER(type) = ? OR LOWER(type) = ?)');
        whereArgs.addAll(['running', 'course']);
      } else if (tf == 'cycling' || tf == 'vélo' || tf == 'velo') {
        conditions.add('(LOWER(type) = ? OR LOWER(type) = ? OR LOWER(type) = ?)');
        whereArgs.addAll(['cycling', 'vélo', 'velo']);
      } else if (tf == 'swimming' || tf == 'natation') {
        conditions.add('(LOWER(type) = ? OR LOWER(type) = ?)');
        whereArgs.addAll(['swimming', 'natation']);
      } else {
        conditions.add('LOWER(type) = LOWER(?)');
        whereArgs.add(typeFilter.trim());
      }
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

  /// UPDATE : Modifie une activité existante (SQLite d'abord, puis MongoDB)
  Future<int> update(PhysicalActivity activity) async {
    if (activity.id == null) {
      throw ArgumentError("Cannot update an activity without an identifier (id)");
    }
    final db = await _dbHelper.database;
    final rowsAffected = await db.update(
      tableName,
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );

    if (rowsAffected > 0) {
      changeNotifier.notify();

      // Pousse la mise à jour vers le backend si remoteId disponible
      if (activity.remoteId != null && Session.instance.token != null) {
        _pushUpdate(activity);
      } else if (Session.instance.token != null) {
        // Si elle n'a pas encore de remoteId, synchroniser
        syncWithBackend();
      }
    }
    return rowsAffected;
  }

  Future<void> _pushUpdate(PhysicalActivity act) async {
    try {
      await _apiService.put('/activities/${act.remoteId}', act.toJson());
    } catch (e) {
      debugPrint('[ActivityService] _pushUpdate error: $e');
    }
  }

  /// DELETE : Supprime une activité par son identifiant local (SQLite et MongoDB)
  Future<int> delete(int id) async {
    final existing = await getById(id);
    final db = await _dbHelper.database;
    final rowsDeleted = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (rowsDeleted > 0) {
      changeNotifier.notify();

      if (existing?.remoteId != null && Session.instance.token != null) {
        _pushDelete(existing!.remoteId!);
      }
    }
    return rowsDeleted;
  }

  Future<void> _pushDelete(String remoteId) async {
    try {
      await _apiService.delete('/activities/$remoteId');
    } catch (e) {
      debugPrint('[ActivityService] _pushDelete error: $e');
    }
  }

  /// READ : Calcule le nombre exact de séances pour le mois en cours (du 1er au dernier jour du mois)
  Future<int> getThisMonthCount({
    String? userId,
    DateTime? referenceDate,
  }) async {
    final activities = await getAll(userId: userId);
    final ref = referenceDate ?? DateTime.now();
    return activities.where((a) {
      final d = a.activityDate.toLocal();
      return d.year == ref.year && d.month == ref.month;
    }).length;
  }

  /// SYNCHRONISATION BIDIRECTIONNELLE & MIGRATION :
  /// 1. Pousse vers MongoDB toutes les activités locales sans remote_id (migration automatique)
  /// 2. Récupère les activités depuis MongoDB et les intègre dans SQLite sans doublons
  Future<void> syncWithBackend() async {
    if (_isSyncing) return;
    if (Session.instance.token == null) return;
    final currentUserId = Session.instance.user?.id;
    if (currentUserId == null || currentUserId.isEmpty) return;

    _isSyncing = true;
    try {
      final db = await _dbHelper.database;

      // -------------------------------------------------------------
      // 1. MIGRATION / PUSH LOCAL -> MONGODB
      // -------------------------------------------------------------
      final unsynced = await db.query(
        tableName,
        where: '(remote_id IS NULL OR remote_id = "") AND (user_id = ? OR user_id IS NULL)',
        whereArgs: [currentUserId],
      );

      if (unsynced.isNotEmpty) {
        final activitiesToSync = unsynced.map((m) {
          final act = PhysicalActivity.fromMap(m);
          return act.toJson();
        }).toList();

        try {
          final resp = await _apiService.post('/activities/sync', {
            'activities': activitiesToSync,
          });

          if (resp is Map && resp['synced'] is List) {
            for (final item in resp['synced']) {
              final localId = item['localId'];
              final remoteId = item['remoteId']?.toString();
              if (localId != null && remoteId != null) {
                await db.update(
                  tableName,
                  {'remote_id': remoteId, 'user_id': currentUserId},
                  where: 'id = ?',
                  whereArgs: [localId],
                );
              }
            }
          }
        } catch (e) {
          debugPrint('[ActivityService] syncBatch error: $e');
        }
      }

      // -------------------------------------------------------------
      // 2. PULL MONGODB -> SQLITE (avec déduplication)
      // -------------------------------------------------------------
      try {
        final remoteData = await _apiService.get('/activities');
        if (remoteData is List) {
          for (final item in remoteData) {
            if (item is! Map) continue;
            final map = Map<String, dynamic>.from(item);
            final remoteId = map['id']?.toString();
            if (remoteId == null) continue;

            final existingByRemote = await db.query(
              tableName,
              where: 'remote_id = ?',
              whereArgs: [remoteId],
              limit: 1,
            );

            final remoteActivity = PhysicalActivity.fromJson(map).copyWith(
              remoteId: remoteId,
              userId: currentUserId,
            );

            if (existingByRemote.isNotEmpty) {
              // Mise à jour de l'enregistrement local avec les données distantes fraîches
              final localId = existingByRemote.first['id'] as int;
              await db.update(
                tableName,
                remoteActivity.toMap()..remove('id'),
                where: 'id = ?',
                whereArgs: [localId],
              );
            } else {
              // Vérification heuristique pour éviter les doublons si l'activité a été insérée
              // sur cet appareil avant d'avoir reçu son remoteId
              final isoDate = remoteActivity.activityDate.toIso8601String();
              final existingByHeuristic = await db.query(
                tableName,
                where: '(user_id = ? OR user_id IS NULL) AND type = ? AND activity_date = ?',
                whereArgs: [currentUserId, remoteActivity.type, isoDate],
                limit: 1,
              );

              if (existingByHeuristic.isNotEmpty) {
                final localId = existingByHeuristic.first['id'] as int;
                await db.update(
                  tableName,
                  remoteActivity.toMap()..remove('id'),
                  where: 'id = ?',
                  whereArgs: [localId],
                );
              } else {
                // Nouvelle activité créée depuis un autre appareil
                await db.insert(
                  tableName,
                  remoteActivity.toMap()..remove('id'),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[ActivityService] pull activities error: $e');
      }

      changeNotifier.notify();
    } catch (e) {
      debugPrint('[ActivityService] syncWithBackend error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
