import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/theme/app_theme.dart';
import 'package:horas_trabajo/core/theme/theme_manager.dart';
import 'package:horas_trabajo/features/root/root_screen.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

class HiApp extends StatelessWidget {
  const HiApp({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeManager>();
    return MaterialApp(
      title: 'Horas Trabajo',
      debugShowCheckedModeBanner: false,
      themeMode: theme.mode,
      theme: AppTheme.light(theme.seed),
      darkTheme: AppTheme.dark(theme.seed),
      home: const RootScreen(),
    );
  }
}