import 'dart:convert';

import 'package:horas_trabajo/data/models/workplace.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el lugar de trabajo y el estado de la geocerca (dentro/fuera),
/// de forma local y accesible también desde el aislado de segundo plano.
class WorkplaceRepository {
  static const _kWorkplace = 'workplace';
  static const _kInside = 'geofence_inside';

  Future<Workplace?> getWorkplace() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWorkplace);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Workplace.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setWorkplace(Workplace w) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWorkplace, jsonEncode(w.toJson()));
  }

  Future<void> clearWorkplace() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWorkplace);
    await prefs.setBool(_kInside, false);
  }

  Future<bool?> getInside() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kInside);
  }

  Future<void> setInside(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kInside, value);
  }
}