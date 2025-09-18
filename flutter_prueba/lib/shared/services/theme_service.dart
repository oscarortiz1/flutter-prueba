import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const _themeKey = 'app_theme_mode';
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_themeKey);
    if (s == 'light') mode.value = ThemeMode.light;
    else if (s == 'dark') mode.value = ThemeMode.dark;
    else mode.value = ThemeMode.system;
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    final s = m == ThemeMode.light ? 'light' : (m == ThemeMode.dark ? 'dark' : 'system');
    await prefs.setString(_themeKey, s);
  }
}
