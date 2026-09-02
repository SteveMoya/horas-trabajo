import 'dart:async';

import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/theme/theme_manager.dart';
import 'package:horas_trabajo/master_app.dart';
import 'package:horas_trabajo/services/background_service.dart';
import 'package:horas_trabajo/services/notifications_service.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fechas y horas en español (intl solo trae en_US por defecto; sin esto
  // los DateFormat('...', 'es') lanzan LocaleDataException y la UI queda vacía).
  Intl.defaultLocale = 'es';
  try {
    await initializeDateFormatting('es');
  } catch (_) {/* el formato caerá a la localidad por defecto si falla */}

  final app = AppState();
  try {
    await app.cargar();
  } catch (_) {/* datos por defecto si algo falla al cargar */}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: app),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
      ],
      child: HiApp(app: app),
    ),
  );

  // Notificaciones y vigilancia: al final y nunca bloquean ni rompen el arranque.
  unawaited(_configurarServicios(app));
}

Future<void> _configurarServicios(AppState app) async {
  try {
    await initializeBackgroundService();
  } catch (e) {
    debugPrint('background service init falló: $e');
  }
  try {
    await NotificationsService.instance.init(
      onMarcarTap: (payload) => _manejarAccionMarcar(app, payload),
    );
  } catch (e) {
    debugPrint('notificaciones init falló: $e');
  }
}

/// Acción "Marcar ahora" desde la notificación de geocerca.
Future<void> _manejarAccionMarcar(AppState app, String payload) async {
  switch (payload) {
    case GeofenceAction.payloadSalida:
      await app.registrarSalida();
      break;
    case GeofenceAction.payloadEntrada:
    default:
      await app.registrarEntrada();
      break;
  }
}