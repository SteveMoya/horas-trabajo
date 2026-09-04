import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/core/theme/theme_manager.dart';
import 'package:horas_trabajo/features/onboarding/onboarding_screen.dart';
import 'package:horas_trabajo/features/root/root_screen.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubre el flujo completo del onboarding rediseñado (9 páginas): que los
/// índices de perfil/ubicación/donación/final sigan siendo correctos, que
/// "Saltar" siga llevando al perfil, y que "Donar ahora" (todavía sin
/// método de pago conectado) avise sin romper la navegación.
///
/// Nota: varias páginas usan `AnimatedIllustration(ambient: true)`, que
/// repite en loop — por eso se usa `pump` con duración acotada en vez de
/// `pumpAndSettle`, igual que ya hace `screenshots_test.dart` con el
/// ticker de `HomeTab`.
void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'es';
    await initializeDateFormatting('es');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpOnboarding(WidgetTester tester, AppState app) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider(create: (_) => ThemeManager()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> continuar(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('recorre las 9 páginas y completa el onboarding', (tester) async {
    final app = AppState();
    await pumpOnboarding(tester, app);

    // 0. Bienvenida
    expect(find.text('Horas Trabajo RD'), findsOneWidget);
    await continuar(tester);

    // 1-3. Qué puedes hacer / cómo funciona
    expect(find.text('Marca con un solo toque'), findsOneWidget);
    await continuar(tester);
    expect(find.text('Tu pago, calculado al segundo'), findsOneWidget);
    await continuar(tester);
    expect(find.text('Reportes, feriados y respaldo'), findsOneWidget);
    await continuar(tester);

    // 4. Características principales
    expect(find.text('Todo lo que necesitas'), findsOneWidget);
    await continuar(tester);

    // 5. Perfil — el botón queda deshabilitado hasta llenar ambos campos
    expect(find.text('Cuéntanos sobre ti'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Ana Pérez');
    await tester.enterText(find.widgetWithText(TextField, 'Salario mensual'), '35000');
    await tester.pump();
    await continuar(tester);

    // 6. Ubicación
    expect(find.text('¿Cómo prefieres marcar?'), findsOneWidget);
    await continuar(tester);

    // 7. Apoya este proyecto — "Donar ahora" avisa que está pendiente,
    // sin bloquear ni fingir un cobro.
    expect(find.text('Apoya este proyecto'), findsOneWidget);
    await tester.tap(find.text('Donar ahora'));
    await tester.pump();
    expect(
      find.text('Muy pronto vas a poder apoyar el proyecto desde acá 💛'),
      findsOneWidget,
    );
    expect(find.text('Continuar sin donar'), findsOneWidget);
    await continuar(tester);

    // 8. Final
    expect(find.text('¡Todo listo!'), findsOneWidget);
    await tester.tap(find.text('Empezar a trabajar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.onboardingCompletado, isTrue);
    expect(app.perfil.nombre, 'Ana Pérez');
    expect(find.byType(RootScreen), findsOneWidget);
  });

  testWidgets('Saltar lleva directo a la página de perfil', (tester) async {
    final app = AppState();
    await pumpOnboarding(tester, app);

    await tester.tap(find.text('Saltar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Cuéntanos sobre ti'), findsOneWidget);
  });
}
