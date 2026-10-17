import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const _key = 'app247.theme_mode';
  SharedPreferencesAsync? _preferences;
  ThemeMode mode = ThemeMode.system;
  bool initialized = false;

  Future<void> initialize() async {
    try {
      final preferences = _preferences ??= SharedPreferencesAsync();
      mode = switch (await preferences.getString(_key)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      mode = ThemeMode.system;
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode value) async {
    if (mode == value) return;
    mode = value;
    notifyListeners();
    try {
      final preferences = _preferences ??= SharedPreferencesAsync();
      await preferences.setString(_key, value.name);
    } catch (_) {
      // O tema continua aplicado em memória quando o storage não está disponível.
    }
  }
}
