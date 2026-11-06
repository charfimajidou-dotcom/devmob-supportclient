import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/db_service.dart';

/// Gère la connexion, l'inscription et la session de l'utilisateur.
class AuthProvider extends ChangeNotifier {
  static const _sessionKey = 'session_user_id';

  AppUser? _user;
  bool _loading = true;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  /// Restaure la session au démarrage de l'application.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    if (id != null) _user = await DbService.instance.getUser(id);
    _loading = false;
    notifyListeners();
  }

  /// Retourne un message d'erreur, ou null si tout va bien.
  Future<String?> login(String email, String password) async {
    final u = await DbService.instance.login(email, password);
    if (u == null) return 'E-mail ou mot de passe incorrect';
    await _saveSession(u);
    return null;
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final u = await DbService.instance.register(name, email, password);
      await _saveSession(u);
      return null;
    } on Exception catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _user = null;
    notifyListeners();
  }

  Future<void> _saveSession(AppUser u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, u.id);
    _user = u;
    notifyListeners();
  }
}
