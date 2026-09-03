import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/features/home/jornada_timer_ring.dart';

/// Capturas aisladas del cronómetro circular en sus tres fases de color
/// (ordinaria → extra → nocturna) para validar visualmente el render.
/// Genera los PNG con: flutter test --update-goldens test/jornada_ring_test.dart
void main() {
  testWidgets('captura anillo fase ordinaria', (tester) async {
    await _capturar(tester, elapsed: const Duration(hours: 5, minutes: 30),
        jornada: const Duration(hours: 8), esNocturno: false,
        golden: 'goldens/ring_ordinaria.png');
  });

  testWidgets('captura anillo fase extra', (tester) async {
    await _capturar(tester, elapsed: const Duration(hours: 10, minutes: 15),
        jornada: const Duration(hours: 8), esNocturno: false,
        golden: 'goldens/ring_extra.png');
  });

  testWidgets('captura anillo fase nocturna', (tester) async {
    await _capturar(tester, elapsed: const Duration(hours: 9, minutes: 5),
        jornada: const Duration(hours: 8), esNocturno: true,
        golden: 'goldens/ring_nocturna.png');
  });
}

Future<void> _capturar(WidgetTester tester,
    {required Duration elapsed, required Duration jornada,
    required bool esNocturno, required String golden}) async {
  tester.view.physicalSize = const Size(390 * 2, 300 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
  );

  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: Center(
        child: JornadaTimerRing(
          elapsed: elapsed,
          jornada: jornada,
          esNocturno: esNocturno,
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 700));

  await expectLater(find.byType(JornadaTimerRing), matchesGoldenFile(golden));
}