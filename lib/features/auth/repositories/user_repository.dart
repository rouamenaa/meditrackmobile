import 'dart:convert';
import 'package:meditrackmobile/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session.dart';

class UserRepository {
  final _api = ApiService();
  final _session = Session.instance;
  final _dbHelper = DatabaseHelper.instance;

  // ---------- Inscription : POST /users ----------
  Future<User> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    String? telephone,
    String? dateNaissance,
    String? sexe,
  }) async {
    final data = await _api.post('/users', {
      'nom': nom.trim(),
      'prenom': prenom.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'telephone': telephone,
      'date_naissance': dateNaissance,
      'sexe': sexe,
    });
    return _startSession(data, remember: true);
  }

  // ---------- Connexion : POST /users/login ----------
  Future<User> login(String email, String password,
      {required bool remember}) async {
    final data = await _api.post('/users/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    return _startSession(data, remember: remember);
  }

  Future<User> _startSession(dynamic data, {required bool remember}) async {
    final user = User.fromJson(Map<String, dynamic>.from(data['user']));
    await _session.start(data['token'] as String, user, remember: remember);
    await _saveCache(user);
    return user;
  }

  // ---------- Au lancement : retrouver l'utilisateur connecté ----------
  Future<User?> restoreSession() async {
    final id = await _session.loadSavedUserId();
    if (id == null) return null;
    try {
      final user = await _fetch(id);
      _session.user = user;
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == null) {
        // Pas de réseau : on utilise la copie locale
        final cached = await _readCache(id);
        if (cached != null) {
          _session.user = cached;
          return cached;
        }
      }
      await _session.clear(); // token expiré, compte supprimé...
      return null;
    }
  }

  // ---------- Profil : GET /users/:id (copie locale si hors ligne) ----------
  Future<User> fetchProfile() async {
    final current = _session.user!;
    try {
      final user = await _fetch(current.id!);
      _session.user = user;
      return user;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow; // 401, 404... : vraie erreur
      return await _readCache(current.id!) ?? current; // hors ligne
    }
  }

  Future<User> _fetch(String id) async {
    final data = await _api.get('/users/$id');
    final user = User.fromJson(Map<String, dynamic>.from(data));
    await _saveCache(user);
    return user;
  }

  // ---------- Déconnexion ----------
  Future<void> logout() async {
    await _session.clear();
    final db = await _dbHelper.database;
    await db.delete('user_cache');
  }

  // ---------- Copie locale SQLite ----------
  Future<void> _saveCache(User user) async {
    final db = await _dbHelper.database;
    await db.insert(
      'user_cache',
      {'id': user.id, 'json': json.encode(user.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> _readCache(String id) async {
    final db = await _dbHelper.database;
    final rows =
    await db.query('user_cache', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return User.fromJson(
        Map<String, dynamic>.from(json.decode(rows.first['json'] as String)));
  }
}