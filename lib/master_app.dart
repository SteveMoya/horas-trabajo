import 'dart:async';

import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/theme/app_theme.dart';
import 'package:horas_trabajo/core/theme/theme_manager.dart';
import 'package:horas_trabajo/features/onboarding/onboarding_screen.dart';
import 'package:horas_trabajo/features/root/root_screen.dart';
import 'package:horas_trabajo/features/updates/update_controller.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

class HiApp extends StatefulWidget {
  const HiApp({super.key, required this.app});

  final AppState app;

  @override
  State<HiApp> createState() => _HiAppState();
}

class _HiAppState extends State<HiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // Al volver a primer plano, recarga desde la base de datos para aplicar
    // cualquier marcado hecho desde un widget de pantalla de inicio mientras
    // la app no estaba al frente (así la UI y los widgets quedan en sincronía)
    // y re-revisa actualizaciones (UpdateController).
    if (estado == AppLifecycleState.resumed) {
      unawaited(widget.app.refrescarDesdeBase());
      unawaited(UpdateController.instance.verificar());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeManager>();
    // Se lee una sola vez (no watch): la bienvenida solo decide la pantalla
    // inicial. Al completarla, OnboardingScreen navega a RootScreen de
    // forma explícita en vez de depender de que este widget se reconstruya.
    final mostrarOnboarding = !context.read<AppState>().onboardingCompletado;
    return MaterialApp(
      title: 'Horas Trabajo',
      debugShowCheckedModeBanner: false,
      navigatorKey: UpdateController.instance.navigatorKey,
      themeMode: theme.mode,
      theme: AppTheme.light(theme.seed),
      darkTheme: AppTheme.dark(theme.seed),
      home: mostrarOnboarding ? const OnboardingScreen() : const RootScreen(),
    );
  }
}