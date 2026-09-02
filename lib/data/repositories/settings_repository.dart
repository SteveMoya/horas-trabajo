import 'dart:convert';

import 'package:horas_trabajo/data/models/employee_profile.dart';
import 'package:horas_trabajo/data/models/rd_pay_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias del usuario y configuración de la app, persistidas localmente.
class SettingsRepository {
  static const _kPerfil = 'perfil';
  static const _kReglas = 'reglas';

  Future<EmployeeProfile> cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPerfil);
    if (raw == null || raw.isEmpty) return const EmployeeProfile();
    try {
      return EmployeeProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const EmployeeProfile();
    }
  }

  Future<void> guardarPerfil(EmployeeProfile perfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPerfil, jsonEncode(perfil.toJson()));
  }

  Future<RdPayRules> cargarReglas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kReglas);
    if (raw == null || raw.isEmpty) return const RdPayRules();
    try {
      return RdPayRules.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const RdPayRules();
    }
  }

  Future<void> guardarReglas(RdPayRules reglas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReglas, jsonEncode(reglas.toJson()));
  }
}