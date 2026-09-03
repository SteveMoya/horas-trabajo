import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:horas_trabajo/data/repositories/workplace_repository.dart';
import 'package:horas_trabajo/services/notifications_service.dart';

/// Constante para el intervalo de revisión de la geocerca (segundos).
const int geofenceIntervalSegundos = 30;

/// Servicio de segundo plano expuesto.
final FlutterBackgroundService backgroundService = FlutterBackgroundService();

/// Inicializa el servicio (aislado de fondo). Llamar una sola vez en main().
Future<void> initializeBackgroundService() async {
  final service = backgroundService;
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStartBackground,
      autoStart: false,
      isForegroundMode: true,
      autoStartOnBoot: false,
      notificationChannelId: NotificationsService.channelId,
      initialNotificationTitle: 'Geocerca del trabajo',
      initialNotificationContent: 'Vigilando llegada y salida',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: const [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onIosHandler,
      onBackground: onIosHandler,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosHandler(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
Future<bool> onStartBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final repo = WorkplaceRepository();
  await NotificationsService.initZonaHoraria();

  var corriendo = true;
  service.on('stopService').listen((_) => corriendo = false);

  while (corriendo) {
    try {
      final wp = await repo.getWorkplace();
      if (wp != null) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          await Future<void>.delayed(
              const Duration(seconds: geofenceIntervalSegundos));
          continue;
        }
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        final dist = Geolocator.distanceBetween(
          wp.latitud,
          wp.longitud,
          pos.latitude,
          pos.longitude,
        );
        final dentro = dist <= wp.radioMetros;
        final previo = await repo.getInside() ?? false;

        if (dentro && !previo) {
          await repo.setInside(true);
          await NotificationsService.llegada(wp);
        } else if (!dentro && previo) {
          await repo.setInside(false);
          await NotificationsService.salida(wp);
        }
      }
    } catch (_) {
      // Cualquier error del ciclo no debe tumbar el aislado ni la app:
      // se reintenta en el siguiente ciclo.
    }
    await Future<void>.delayed(const Duration(seconds: geofenceIntervalSegundos));
  }
  return true;
}