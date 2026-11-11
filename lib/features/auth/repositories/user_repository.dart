import 'dart:convert';
import 'package:meditrackmobile/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session.dart';

/// Résultat d'une inscription : le compte créé + l'état de l'email de vérification.
class RegistrationResult {
  final User user;
  final bool emailEnvoye;
  final String? emailError;

  RegistrationResult({
    required this.user,
    required this.emailEnvoye,
    this.emailError,
  });
}

class UserRepository {
  final _api = ApiService();
  final _session = Session.instance;
  final _dbHelper = DatabaseHelper.instance;

  // ---------- Inscription : POST /users ----------
  Future<RegistrationResult> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    String role = 'patient',
    String? telephone,
    String? dateNaissance,
    String? sexe,
  }) async {
    final data = await _api.post('/users', {
      'nom': nom.trim(),
      'prenom': prenom.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role,
      'telephone': telephone,
      'date_naissance': dateNaissance,
      'sexe': sexe,
    });
    final user = await _startSession(data, remember: true);
    return RegistrationResult(
      user: user,
      emailEnvoye: data['email_envoye'] as bool? ?? true,
      emailError: data['email_error'] as String?,
    );
  }

  // ---------- Vérification de l'email ----------
  // Renvoie un nouveau code de vérification à l'adresse donnée.
  Future<void> sendVerificationCode(String email) =>
      _api.post('/users/verify/send', {'email': email.trim().toLowerCase()});

  // Confirme le compte avec le code reçu. Ouvre la session si succès.
  Future<User> confirmVerification(String email, String code) async {
    final data = await _api.post('/users/verify/confirm', {
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
    });
    return _startSession(data, remember: true);
  }

  // ---------- Mot de passe oublié ----------
  Future<void> forgotPassword(String email) =>
      _api.post('/users/forgot-password', {'email': email.trim().toLowerCase()});

  Future<void> resetPassword(String email, String code, String newPassword) =>
      _api.post('/users/reset-password', {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'new_password': newPassword,
      });

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
  Future<User?> restoreSession({bool afterBiometric = false}) async {
    final id = await _session.loadSavedUserId();
    if (id == null) return null;
    if (!afterBiometric && await _session.wasExplicitlySignedOut) return null;
    if (!await _session.activateSavedToken()) {
      await invalidateSession();
      return null;
    }
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
      await invalidateSession(); // token expiré, compte supprimé...
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

  // ---------- Modification du profil : PUT /users/:id ----------
  Future<User> updateProfile({
    required String nom,
    required String prenom,
    String? telephone,
    String? dateNaissance,
    String? sexe,
    String? groupeSanguin,
    String? conditionMedicale,
    String? contactUrgenceNom,
    String? contactUrgenceLien,
    String? contactUrgenceTel,
    String? assuranceNom,
    String? assurancePolice,
    String? specialite,
    String? rppsAdeli,
    String? etablissement,
    String? horairesConsultation,
  }) async {
    final id = _session.user!.id!;
    final data = await _api.put('/users/$id', {
      'nom': nom.trim(),
      'prenom': prenom.trim(),
      'telephone': telephone,
      'date_naissance': dateNaissance,
      'sexe': sexe,
      'groupe_sanguin': groupeSanguin,
      'condition_medicale': conditionMedicale,
      'contact_urgence_nom': contactUrgenceNom,
      'contact_urgence_lien': contactUrgenceLien,
      'contact_urgence_tel': contactUrgenceTel,
      'assurance_nom': assuranceNom,
      'assurance_police': assurancePolice,
      'specialite': specialite,
      'rpps_adeli': rppsAdeli,
      'etablissement': etablissement,
      'horaires_consultation': horairesConsultation,
    });
    final user = User.fromJson(Map<String, dynamic>.from(data));
    _session.user = user;
    await _saveCache(user);
    return user;
  }

  // ---------- Photo de profil : POST /users/:id/photo ----------
  Future<User> uploadPhoto(String filePath) async {
    final id = _session.user!.id!;
    final data =
        await _api.postMultipart('/users/$id/photo', 'image', filePath);
    final user = User.fromJson(Map<String, dynamic>.from(data));
    _session.user = user;
    await _saveCache(user);
    return user;
  }

  // ---------- Déconnexion ----------
  Future<void> logout() async {
    final preservedForBiometric = await _session.signOut();
    if (preservedForBiometric) return;
    await _deleteUserCache();
  }

  /// Clears remembered credentials after an expired/revoked session.
  Future<void> invalidateSession() async {
    await _session.clear();
    await _deleteUserCache();
  }

  Future<void> _deleteUserCache() async {
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
