import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla el tema de la app (modo + color primario) y lo persiste localmente.
class ThemeManager extends ChangeNotifier {
  ThemeManager({ThemeMode mode = ThemeMode.system, int seedIndex = 0})
      : _mode = mode,
        _seedIndex = seedIndex {
    _cargar();
  }

  static const _kMode = 'theme_mode';
  static const _kSeed = 'theme_seed';

  ThemeMode _mode;
  int _seedIndex;

  ThemeMode get mode => _mode;
  int get seedIndex => _seedIndex;
  Color get seed => ThemePalettes.seeds[_seedIndex];

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final tipo = prefs.getString(_kMode);
    if (tipo != null) {
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == tipo,
        orElse: () => ThemeMode.system,
      );
    }
    _seedIndex = prefs.getInt(_kSeed) ?? 0;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode nuevo) async {
    _mode = nuevo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMode, nuevo.name);
  }

  Future<void> setSeed(int index) async {
    if (index < 0 || index >= ThemePalettes.seeds.length) return;
    _seedIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSeed, index);
  }
}