import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/theme/theme_manager.dart';
import 'package:horas_trabajo/master_app.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = AppState();
  await app.cargar(); // carga perfil, reglas, sesiones y sesión activa

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