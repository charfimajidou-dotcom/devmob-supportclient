import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode clair / sombre (bonus du projet), mémorisé entre les sessions.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'dark_mode';
  bool _dark = false;

  bool get isDark => _dark;
  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dark = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    _dark = !_dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _dark);
  }
}
