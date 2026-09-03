import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:horas_trabajo/data/models/employee_profile.dart';
import 'package:horas_trabajo/data/models/rd_pay_rules.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/data/models/workplace.dart';
import 'package:horas_trabajo/data/repositories/settings_repository.dart';
import 'package:horas_trabajo/data/repositories/work_session_repository.dart';
import 'package:horas_trabajo/data/repositories/workplace_repository.dart';
import 'package:horas_trabajo/domain/salary/salary_engine.dart';
import 'package:horas_trabajo/services/background_service.dart';
import 'package:horas_trabajo/services/notifications_service.dart';
import 'package:horas_trabajo/services/reminder_service.dart';

/// Resultado de intentar activar la vigilancia de geocerca.
enum MonitoreoResultado {
  /// Vigilancia activada correctamente.
  activado,

  /// Aún no hay un lugar de trabajo guardado.
  sinLugarTrabajo,

  /// El usuario denegó el permiso de ubicación.
  permisoDenegado,

  /// Permiso denegado de forma permanente (Android no vuelve a preguntar).
  permisoPermanente,

  /// La ubicación/GPS está apagado en el sistema.
  gpsApagado,

  /// Android 13+: las notificaciones están denegadas y el foreground service
  /// necesita publicar un aviso persistente. No se arranca el servicio
  /// (evita un crash nativo); se pide al usuario activarlas.
  notificacionesDenegadas,

  /// No se pudo iniciar el servicio en segundo plano (p. ej. fallo nativo o
  /// de plataforma). La app NO se cierra: se deja la vigilancia desactivada.
  fallo,
}

/// Estado global de la app: perfil, reglas RD, sesiones, lugar de trabajo,
/// vigilancia de geocerca y motor de cálculo. Expuesto por `provider`.
class AppState extends ChangeNotifier {
  AppState({
    SettingsRepository? settings,
    WorkSessionRepository? sessions,
    WorkplaceRepository? workplaceRepo,
    ReminderService? reminders,
  })  : _settings = settings ?? SettingsRepository(),
        _sessions = sessions ?? WorkSessionRepository(),
        _workplaceRepo = workplaceRepo ?? WorkplaceRepository(),
        _reminders = reminders ?? ReminderService();

  final SettingsRepository _settings;
  final WorkSessionRepository _sessions;
  final WorkplaceRepository _workplaceRepo;
  final ReminderService _reminders;

  EmployeeProfile _perfil = const EmployeeProfile();
  RdPayRules _reglas = const RdPayRules();
  List<WorkSession> _sesiones = [];
  WorkSession? _activa;
  Workplace? _workplace;
  bool _monitoreando = false;
  bool _dentro = false;
  bool _cargando = true;
  bool _procesando = false;
  bool _usarUbicacion = true;
  bool _recordatoriosActivos = false;
  Timer? _tick;

  EmployeeProfile get perfil => _perfil;
  RdPayRules get reglas => _reglas;
  List<WorkSession> get sesiones => List.unmodifiable(_sesiones);
  WorkSession? get activa => _activa;
  Workplace? get workplace => _workplace;
  bool get monitoreando => _monitoreando;
  bool get dentro => _dentro;
  bool get cargando => _cargando;
  bool get procesando => _procesando;
  bool get usarUbicacion => _usarUbicacion;
  bool get recordatoriosActivos => _recordatoriosActivos;

  SalaryEngine get motor =>
      SalaryEngine(salarioMensual: _perfil.salarioMensual, reglas: _reglas);

  bool get perfilCompleto => _perfil.perfilCompleto;

  /// [SOLO TEST/REVISIONES] Inyecta estado de demostración sin tocar la base
  /// de datos. Útil para capturas (golden) y previsualización de la UI.
  @visibleForTesting
  void inyectarEstadoDemo({
    EmployeeProfile perfil = const EmployeeProfile(),
    List<WorkSession> sesiones = const [],
    WorkSession? activa,
    Workplace? workplace,
    bool monitoreando = false,
    bool dentro = false,
    bool usarUbicacion = true,
    bool recordatoriosActivos = false,
  }) {
    _perfil = perfil;
    _reglas = const RdPayRules();
    _sesiones = List.of(sesiones);
    _activa = activa;
    _workplace = workplace;
    _monitoreando = monitoreando;
    _dentro = dentro;
    _usarUbicacion = usarUbicacion;
    _recordatoriosActivos = recordatoriosActivos;
    _cargando = false;
    _procesando = false;
    notifyListeners();
  }

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    final resultados = await Future.wait([
      _settings.cargarPerfil(),
      _settings.cargarReglas(),
      _sessions.obtenerTodas(),
      _sessions.obtenerEnProgreso(),
      _workplaceRepo.getWorkplace(),
      _workplaceRepo.getInside(),
      _settings.cargarUsarUbicacion(),
      _settings.cargarRecordatorios(),
    ]);
    _perfil = resultados[0] as EmployeeProfile;
    _reglas = resultados[1] as RdPayRules;
    _sesiones = resultados[2] as List<WorkSession>;
    _activa = resultados[3] as WorkSession?;
    _workplace = resultados[4] as Workplace?;
    _dentro = resultados[5] as bool? ?? false;
    _usarUbicacion = resultados[6] as bool? ?? true;
    _recordatoriosActivos = resultados[7] as bool? ?? false;
    _cargando = false;

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activa != null) notifyListeners();
    });

    // Reprograma con el patrón más reciente en cada arranque; si el usuario
    // los tiene apagados, no hace nada (evita alarmas huérfanas).
    if (_recordatoriosActivos) {
      unawaited(_reminders.recalcularYProgramar(_sesiones));
    }

    notifyListeners();
  }

  /// Activa/desactiva los recordatorios "¿olvidaste marcar?". Al activar,
  /// se calculan y programan de inmediato con el historial actual.
  Future<void> guardarRecordatorios(bool valor) async {
    _recordatoriosActivos = valor;
    notifyListeners();
    await _settings.guardarRecordatorios(valor);
    if (valor) {
      await _reminders.recalcularYProgramar(_sesiones);
    } else {
      await NotificationsService.cancelarRecordatorios();
    }
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

  /// Activa/desactiva el modo 100% manual (sin GPS ni permiso de ubicación).
  /// Al desactivar el uso de ubicación se apaga también la vigilancia de
  /// geocerca, ya que depende de la posición del dispositivo.
  Future<void> guardarUsarUbicacion(bool valor) async {
    _usarUbicacion = valor;
    if (!valor && _monitoreando) await desactivarMonitor();
    notifyListeners();
    await _settings.guardarUsarUbicacion(valor);
  }

  // ---------------- Lugar de trabajo y geocerca ----------------

  Future<void> guardarWorkplace(Workplace w) async {
    _workplace = w;
    await _workplaceRepo.setWorkplace(w);
    notifyListeners();
  }

  Future<void> quitarWorkplace() async {
    if (_monitoreando) await desactivarMonitor();
    _workplace = null;
    _dentro = false;
    await _workplaceRepo.clearWorkplace();
    notifyListeners();
  }

  /// Solicita el permiso de ubicación con geolocator (más fiable que
  /// permission_handler: muestra el popup del sistema). Con [fondo]=true
  /// intenta además obtener el acceso "Toda la hora" (Android).
  Future<LocationPermission> solicitarPermiso({bool fondo = false}) async {
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    // Android: una segunda petición ofrece la opción "Permitir todo el tiempo",
    // necesaria para que la geocerca funcione en segundo plano.
    if (fondo &&
        permiso == LocationPermission.whileInUse &&
        (await Geolocator.checkPermission()) == LocationPermission.whileInUse) {
      permiso = await Geolocator.requestPermission();
    }
    return permiso;
  }

  /// Pide permiso de ubicación (y de fondo en Android) y devuelve [lat,lng],
  /// o null si el usuario lo deniega / no hay señal.
  Future<List<double>?> pedirUbicacion({bool fondo = false}) async {
    try {
      final permiso = await solicitarPermiso(fondo: fondo);
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return [pos.latitude, pos.longitude];
    } catch (_) {
      return null;
    }
  }

  /// Activa la vigilancia de llegada/salida (foreground service + geocerca).
  /// Nunca lanza excepciones: cualquier fallo devuelve [MonitoreoResultado.fallo]
  /// para que la app no se cierre.
  Future<MonitoreoResultado> activarMonitor() async {
    if (_workplace == null) return MonitoreoResultado.sinLugarTrabajo;

    try {
      final permiso = await solicitarPermiso(fondo: true);
      if (permiso == LocationPermission.deniedForever) {
        return MonitoreoResultado.permisoPermanente;
      }
      if (permiso == LocationPermission.denied) {
        return MonitoreoResultado.permisoDenegado;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return MonitoreoResultado.gpsApagado;
      }

      // El foreground service necesita publicar una notificación persistente;
      // en Android 13+ eso exige el permiso POST_NOTIFICATIONS.
      try {
        await NotificationsService.instance.requestPermission();
      } catch (_) {/* se chequea igualmente debajo */}
      if (!await NotificationsService.notificacionesPermitidas()) {
        return MonitoreoResultado.notificacionesDenegadas;
      }

      // El canal debe existir ANTES de arrancar el servicio: si no,
      // startForeground() falla con CannotPostForegroundServiceNotificationException
      // y el sistema mata la app (main.dart lo crea de forma asíncrona al
      // arrancar, pero no hay garantía de que ya haya terminado aquí).
      try {
        await NotificationsService.crearCanalGeofence();
      } catch (_) {/* se reintenta igual al arrancar el servicio */}

      try {
        await backgroundService.startService();
      } catch (e) {
        _monitoreando = false;
        return MonitoreoResultado.fallo;
      }

      _monitoreando = true;
      notifyListeners();
      return MonitoreoResultado.activado;
    } catch (e) {
      _monitoreando = false;
      debugPrint('activarMonitor falló: $e');
      return MonitoreoResultado.fallo;
    }
  }

  Future<void> desactivarMonitor() async {
    backgroundService.invoke('stopService');
    _monitoreando = false;
    await _workplaceRepo.setInside(false);
    _dentro = false;
    notifyListeners();
  }

  // ---------------- Marcado ----------------

  /// Marca de entrada. Opcional [ubicacion] capturada por la UI. [esFeriado]
  /// permite marcar la jornada como feriado desde el aviso de la UI (ver
  /// FeriadosRD) sin pasar por la hoja de edición manual.
  Future<void> registrarEntrada({
    List<double>? ubicacion,
    bool esFeriado = false,
  }) async {
    if (_procesando || _activa != null) return;
    _procesando = true;
    notifyListeners();

    final sesion = await _sessions.insertar(WorkSession(
      id: 0,
      inicio: DateTime.now(),
      latitud: ubicacion?[0],
      longitud: ubicacion?[1],
      esFeriado: esFeriado,
    ));
    _activa = sesion;
    _sesiones = [sesion, ..._sesiones];
    _procesando = false;
    notifyListeners();
  }

  /// Marca de salida.
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