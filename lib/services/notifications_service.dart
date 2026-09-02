import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:horas_trabajo/data/models/workplace.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

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

  static FlutterLocalNotificationsPlugin? _plugin;

  /// Alguien tocó la acción "Marcar ahora" con [payload].
  static Future<void> Function(String payload)? onMarcar;

  static FlutterLocalNotificationsPlugin get plugin =>
      _plugin ??= FlutterLocalNotificationsPlugin();

  /// Inicializa la zona horaria (solo datos; no se programan notificaciones).
  static Future<void> initZonaHoraria() async {
    tzdata.initializeTimeZones();
    // Solo usamos notificaciones inmediatas (show), no programadas,
    // así que no requerimos fijar la zona local del dispositivo.
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

    // Permiso de notificaciones (Android 13+).
    await requestPermission();
  }

  Future<void> requestPermission() async {
    try {
      final value = plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await value?.requestNotificationsPermission();
    } catch (_) {/* no disponible */}
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
}