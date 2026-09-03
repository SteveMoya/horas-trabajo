import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:horas_trabajo/data/models/workplace.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Payloads usados para que al tocar la notificación se pueda marcar.
class GeofenceAction {
  static const mark = 'mark';
  static const payloadEntrada = 'mark:entrada';
  static const payloadSalida = 'mark:salida';
}

/// Servicio de notificaciones locales.
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  static const channelId = 'geofence';
  static const int geofenceNotificationId = 7001;
  static const int marcarNotificacionId = 7002;

  static const _channelRecordatorios = 'recordatorios';
  static const idRecordatorioEntrada = 7003;
  static const idRecordatorioSalida = 7004;

  static FlutterLocalNotificationsPlugin? _plugin;

  /// Alguien tocó la acción "Marcar ahora" con [payload].
  static Future<void> Function(String payload)? onMarcar;

  static FlutterLocalNotificationsPlugin get plugin =>
      _plugin ??= FlutterLocalNotificationsPlugin();

  /// Inicializa la zona horaria para poder programar notificaciones
  /// (recordatorios inteligentes) con `zonedSchedule`.
  ///
  /// República Dominicana usa un único huso horario fijo (UTC-4, sin
  /// horario de verano), así que se fija directamente en vez de detectar
  /// la zona del dispositivo: eso evita reintroducir `flutter_timezone`,
  /// que se quitó antes por incompatibilidad con el embedding de Flutter
  /// (ver historial de commits de background_service.dart).
  static Future<void> initZonaHoraria() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Santo_Domingo'));
    } catch (_) {/* datos de zona horaria no disponibles */}
  }

  /// Inicializa el plugin (una vez) y registra el manejador de toques.
  Future<void> init({Future<void> Function(String payload)? onMarcarTap}) async {
    if (onMarcarTap != null) onMarcar = onMarcarTap;

    await initZonaHoraria();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) {
        if (resp.actionId == GeofenceAction.mark ||
            (resp.payload?.startsWith('mark:') ?? false)) {
          onMarcar?.call(resp.payload ?? GeofenceAction.payloadEntrada);
        }
      },
    );

    // El foreground service (background_service.dart) publica su notificación
    // persistente en este mismo canal sin crearlo él mismo; si no existe
    // todavía, Android rechaza el startForeground() con
    // CannotPostForegroundServiceNotificationException y mata la app.
    await crearCanalGeofence();

    // Permiso de notificaciones (Android 13+).
    await requestPermission();
  }

  /// Crea (si no existe) el canal de notificaciones usado tanto para los
  /// avisos de geocerca como para la notificación persistente del
  /// foreground service de vigilancia.
  static Future<void> crearCanalGeofence() async {
    const canal = AndroidNotificationChannel(
      channelId,
      'Geocerca del trabajo',
      description: 'Avisos al llegar o salir del lugar de trabajo',
      importance: Importance.high,
    );
    try {
      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(canal);
    } catch (_) {/* dispositivo sin soporte */}
  }

  Future<void> requestPermission() async {
    try {
      final value = plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await value?.requestNotificationsPermission();
    } catch (_) {/* no disponible */}
  }

  /// ¿Están las notificaciones habilitadas en el sistema (Android 13+)?
  /// Devuelve true si no se puede determinar (p. ej. iOS/web o sin soporte).
  static Future<bool> notificacionesPermitidas() async {
    try {
      final value = plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await value?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Notificación de geocerca (llegada o salida).
  static Future<void> showGeofence({
    required int id,
    required String title,
    required String body,
    String payload = '',
    bool conAccionMarcar = true,
  }) async {
    final android = AndroidNotificationDetails(
      channelId,
      'Geocerca del trabajo',
      channelDescription: 'Avisos al llegar o salir del lugar de trabajo',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      actions: conAccionMarcar
          ? [
              const AndroidNotificationAction(
                GeofenceAction.mark,
                'Marcar ahora',
                cancelNotification: false,
              ),
            ]
          : null,
    );
    final details = NotificationDetails(
      android: android,
      iOS: const DarwinNotificationDetails(),
    );
    try {
      await plugin.show(id, title, body, details, payload: payload);
    } catch (_) {/* dispositivo sin soporte */}
  }

  /// Llegada al trabajo.
  static Future<void> llegada(Workplace w) => showGeofence(
        id: geofenceNotificationId,
        title: '📍 Llegaste al trabajo',
        body: 'Estás en ${w.nombre}. ¿Marcar la entrada?',
        payload: GeofenceAction.payloadEntrada,
      );

  /// Salida del trabajo.
  static Future<void> salida(Workplace w) => showGeofence(
        id: geofenceNotificationId,
        title: '🚪 Saliste del trabajo',
        body: 'Te alejaste de ${w.nombre}. ¿Marcar la salida?',
        payload: GeofenceAction.payloadSalida,
      );

  // ---------------- Recordatorios inteligentes ----------------

  static Future<void> _crearCanalRecordatorios() async {
    const canal = AndroidNotificationChannel(
      _channelRecordatorios,
      'Recordatorios',
      description: 'Avisos de "¿olvidaste marcar?" según tu horario habitual',
      importance: Importance.defaultImportance,
    );
    try {
      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(canal);
    } catch (_) {/* dispositivo sin soporte */}
  }

  /// Programa (o reprograma, si ya existía) un recordatorio diario a las
  /// [hora]:[minuto] locales. Es best-effort: no verifica en el momento del
  /// disparo si la acción ya se hizo ese día.
  static Future<void> programarRecordatorioDiario({
    required int id,
    required String title,
    required String body,
    required int hora,
    required int minuto,
  }) async {
    await _crearCanalRecordatorios();
    const android = AndroidNotificationDetails(
      _channelRecordatorios,
      'Recordatorios',
      channelDescription:
          'Avisos de "¿olvidaste marcar?" según tu horario habitual',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
    );
    try {
      await plugin.zonedSchedule(
        id,
        title,
        body,
        _proximaOcurrencia(hora, minuto),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {/* dispositivo sin soporte de alarmas exactas/zonedSchedule */}
  }

  static Future<void> cancelarRecordatorios() async {
    try {
      await plugin.cancel(idRecordatorioEntrada);
      await plugin.cancel(idRecordatorioSalida);
    } catch (_) {/* nada que cancelar */}
  }

  static tz.TZDateTime _proximaOcurrencia(int hora, int minuto) {
    final ahora = tz.TZDateTime.now(tz.local);
    var fecha = tz.TZDateTime(tz.local, ahora.year, ahora.month, ahora.day, hora, minuto);
    if (fecha.isBefore(ahora)) fecha = fecha.add(const Duration(days: 1));
    return fecha;
  }
}