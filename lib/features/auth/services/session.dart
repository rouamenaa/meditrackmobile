import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class Session {
  Session._();
  static final Session instance = Session._();

  String? token; // en mémoire pendant que l'app tourne
  User? user; // utilisateur courant

  Future<void> start(String token, User user, {required bool remember}) async {
    this.token = token;
    this.user = user;
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString('token', token);
      await prefs.setString('user_id', user.id!);
    } else {
      await prefs.remove('token');
      await prefs.remove('user_id');
    }
  }

  /// Relit la session sauvegardée. Retourne l'id, ou null s'il n'y en a pas.
  Future<String?> loadSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString('token');
    final id = prefs.getString('user_id');
    if (t == null || id == null) return null;
    token = t;
    return id;
  }

  Future<void> clear() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
  }
}