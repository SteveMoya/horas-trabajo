import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/core/illustrations/app_illustrations.dart';
import 'package:horas_trabajo/core/widgets/animated_illustration.dart';
import 'package:horas_trabajo/core/widgets/app_illustration.dart';

void main() {
  for (final asset in AppIllustrationAsset.values) {
    testWidgets('AppIllustration renderiza ${asset.name} sin errores', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppIllustration(asset, size: 120)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('AnimatedIllustration completa su entrada sin errores', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedIllustration(
            AppIllustrationAsset.welcome,
            size: 160,
            ambient: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
