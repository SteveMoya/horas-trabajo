import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/core/theme/app_theme.dart';
import 'package:horas_trabajo/data/models/employee_profile.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/data/models/workplace.dart';
import 'package:horas_trabajo/features/home/home_tab.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Captura fiel de la pantalla "Marcar" (Inicio) para usos de previsualización.
/// Genera el PNG con: flutter test --update-goldens test/screenshots_test.dart
void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'es';
    await initializeDateFormatting('es');
  });

  testWidgets('captura pantalla Inicio', (tester) async {
    // Reloj fijo + inicio fijo: la cabecera (hora) y el relleno del cronómetro
    // (5h30m → fase ordinaria) quedan deterministas en cualquier corrida.
    final ahora = DateTime(2026, 1, 15, 12, 30);
    final inicio = ahora.subtract(const Duration(hours: 5, minutes: 30));

    final activa = WorkSession(
      id: 1,
      inicio: inicio,
      latitud: 18.4861,
      longitud: -69.9312,
    );

    final app = AppState();
    app.inyectarEstadoDemo(
      perfil: const EmployeeProfile(nombre: 'Juan Pérez', salarioMensual: 32000),
      sesiones: [activa],
      activa: activa,
      workplace: Workplace(
        id: 1,
        latitud: 18.4861,
        longitud: -69.9312,
        nombre: 'Torre Empresarial',
        radioMetros: 150,
        creadoEn: inicio,
      ),
      monitoreando: true,
      dentro: true,
    );

    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final seed = ThemePalettes.seeds[0];
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: HomeTab(clock: () => ahora),
        ),
      ),
    );
    await tester.pump();
    // Deja terminar la entrada escalonada de las tarjetas (duración máxima
    // ~580ms) sin usar pumpAndSettle: el ticker de 1s de HomeTab reprograma
    // un frame cada segundo y nunca "asienta".
    await tester.pump(const Duration(milliseconds: 650));

    await expectLater(
      find.byType(HomeTab),
      matchesGoldenFile('goldens/home.png'),
    );
  });
}