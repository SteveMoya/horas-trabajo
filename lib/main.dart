import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/theme/theme_manager.dart';
import 'package:horas_trabajo/master_app.dart';
import 'package:horas_trabajo/services/background_service.dart';
import 'package:horas_trabajo/services/notifications_service.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final app = AppState();
  await app.cargar(); // perfil, reglas, sesiones, lugar de trabajo

  await initializeBackgroundService();
  await NotificationsService.instance.init(
    onMarcarTap: (payload) => _manejarAccionMarcar(app, payload),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: app),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
      ],
      child: HiApp(app: app),
    ),
  );
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