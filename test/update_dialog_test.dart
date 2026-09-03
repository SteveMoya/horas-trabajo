import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/features/updates/update_dialog.dart';
import 'package:horas_trabajo/services/update_service.dart';

/// Previsualiza el diálogo de actualización (estado inicial, con notas).
void main() {
  testWidgets('captura diálogo de actualización', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
    );

    const info = UpdateInfo(
          tag: 'v0.7.0',
          version: '0.7.0',
          apkUrl: 'https://example.com/horas-trabajo-v0.7.0.apk',
          apkSizeBytes: 63400000, // ~60 MB
          notes:
              '• Rediseño del cronómetro circular de jornada\n'
              '• Notificaciones de actualización automática\n'
              '• Correcciones de estabilidad en la vigilancia\n'
              '• Mejoras de accesibilidad',
          releasedAt: null,
          prerelease: true,
        );

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const UpdateDialog(info: info),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(UpdateDialog),
      matchesGoldenFile('goldens/update_dialog.png'),
    );
  });
}