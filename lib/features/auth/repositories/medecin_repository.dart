import '../models/medecin.dart';
import '../services/api_service.dart';

/// Médecins gérés côté serveur (MongoDB), exposés via /users/:id/medecins.
/// (Pas de table SQLite locale "medecins" dans DatabaseHelper.)
class MedecinRepository {
  final _api = ApiService();

  Future<List<Medecin>> getByUser(String userId) async {
    final data = await _api.get('/users/$userId/medecins');
    final list = (data as List?) ?? const [];
    return list
        .map((e) => Medecin.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Medecin> add(String userId, Medecin m) async {
    final data = await _api.post('/users/$userId/medecins', m.toJson()..remove('id'));
    return Medecin.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<bool> delete(String userId, String medId) async {
    await _api.delete('/users/$userId/medecins/$medId');
    return true;
  }
}