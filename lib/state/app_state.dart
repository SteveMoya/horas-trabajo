import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:horas_trabajo/data/models/employee_profile.dart';
import 'package:horas_trabajo/data/models/rd_pay_rules.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/data/repositories/settings_repository.dart';
import 'package:horas_trabajo/data/repositories/work_session_repository.dart';
import 'package:horas_trabajo/domain/salary/salary_engine.dart';
import 'package:horas_trabajo/services/geo_service.dart';

/// Estado global de la app: perfil, reglas RD, sesiones, sesión activa y motor
/// de cálculo. Expuesto por `provider`.
class AppState extends ChangeNotifier {
  AppState({
    SettingsRepository? settings,
    WorkSessionRepository? sessions,
    GeoService? geo,
  })  : _settings = settings ?? SettingsRepository(),
        _sessions = sessions ?? WorkSessionRepository(),
        _geo = geo ?? GeoService();

  final SettingsRepository _settings;
  final WorkSessionRepository _sessions;
  final GeoService _geo;

  EmployeeProfile _perfil = const EmployeeProfile();
  RdPayRules _reglas = const RdPayRules();
  List<WorkSession> _sesiones = [];
  WorkSession? _activa;
  bool _cargando = true;
  bool _procesando = false;
  Timer? _tick;

  EmployeeProfile get perfil => _perfil;
  RdPayRules get reglas => _reglas;
  List<WorkSession> get sesiones => List.unmodifiable(_sesiones);
  WorkSession? get activa => _activa;
  bool get cargando => _cargando;
  bool get procesando => _procesando;

  /// Motor listo para calcular con el perfil y reglas actuales.
  SalaryEngine get motor =>
      SalaryEngine(salarioMensual: _perfil.salarioMensual, reglas: _reglas);

  bool get perfilCompleto => _perfil.perfilCompleto;

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    final resultados = await Future.wait([
      _settings.cargarPerfil(),
      _settings.cargarReglas(),
      _sessions.obtenerTodas(),
      _sessions.obtenerEnProgreso(),
    ]);
    _perfil = resultados[0] as EmployeeProfile;
    _reglas = resultados[1] as RdPayRules;
    _sesiones = resultados[2] as List<WorkSession>;
    _activa = resultados[3] as WorkSession?;
    _cargando = false;

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activa != null) notifyListeners(); // reloj en vivo en Home
    });

    notifyListeners();
  }

  Future<void> guardarPerfil(EmployeeProfile perfil) async {
    _perfil = perfil;
    notifyListeners();
    await _settings.guardarPerfil(perfil);
  }

  Future<void> guardarReglas(RdPayRules reglas) async {
    _reglas = reglas;
    notifyListeners();
    await _settings.guardarReglas(reglas);
  }

  /// Marca de entrada: recoge GPS (si es posible) y abre una sesión.
  Future<void> registrarEntrada() async {
    if (_procesando || _activa != null) return;
    _procesando = true;
    notifyListeners();

    final gps = await _geo.ubicacionActual();
    final sesion = await _sessions.insertar(WorkSession(
      id: 0,
      inicio: DateTime.now(),
      latitud: gps?[0],
      longitud: gps?[1],
    ));
    _activa = sesion;
    _sesiones = [sesion, ..._sesiones];
    _procesando = false;
    notifyListeners();
  }

  /// Marca de salida: cierra la sesión activa con el momento actual.
  Future<void> registrarSalida() async {
    final activa = _activa;
    if (_procesando || activa == null) return;
    _procesando = true;
    notifyListeners();

    final cerrada = activa.copyWith(fin: DateTime.now());
    await _sessions.actualizar(cerrada);
    _activa = null;
    _sesiones = [
      cerrada,
      ..._sesiones.where((s) => s.id != cerrada.id),
    ];
    _procesando = false;
    notifyListeners();
  }

  Future<void> actualizarSesion(WorkSession sesion) async {
    await _sessions.actualizar(sesion);
    _sesiones = [
      for (final s in _sesiones) s.id == sesion.id ? sesion : s,
    ];
    if (_activa?.id == sesion.id) _activa = sesion;
    notifyListeners();
  }

  Future<void> eliminarSesion(int id) async {
    await _sessions.eliminar(id);
    _sesiones = _sesiones.where((s) => s.id != id).toList();
    if (_activa?.id == id) _activa = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}