import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class Session {
  Session._();
  static final Session instance = Session._();

  static const _tokenKey = 'token';
  static const _userIdKey = 'user_id';
  static const _signedOutKey = 'explicitly_signed_out';

  String? token;
  User? user;

  Future<void> start(String token, User user, {required bool remember}) async {
    this.token = token;
    this.user = user;
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, user.id!);
      await prefs.remove(_signedOutKey);
    } else {
      await _clearSavedSession(prefs);
    }
  }

  Future<String?> loadSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_userIdKey);
    final savedToken = prefs.getString(_tokenKey);
    return id == null || savedToken == null ? null : id;
  }

  Future<bool> get wasExplicitlySignedOut async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_signedOutKey) ?? false;
  }

  Future<bool> activateSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null || prefs.getString(_userIdKey) == null) return false;
    token = savedToken;
    return true;
  }

  Future<bool> signOut() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    final hasRememberedSession =
        prefs.getString(_tokenKey) != null && prefs.getString(_userIdKey) != null;
    if (!hasRememberedSession) {
      await _clearSavedSession(prefs);
      return false;
    }
    await prefs.setBool(_signedOutKey, true);
    return true;
  }

  Future<void> clear() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await _clearSavedSession(prefs);
  }

  Future<void> _clearSavedSession(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_signedOutKey);
  }
}
