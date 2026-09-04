import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/services/home_widget_service.dart';

/// Regresión de la sincronización app → widgets: `actualizarHomeWidget` debe
/// refrescar SIEMPRE los 3 providers (reloj, marcador y reporte), aunque el
/// isolate no pueda leer la base o formatear la fecha (el refresco no puede
/// quedarse a medias ni dejar el widget "congelado" tras marcar).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('actualizarHomeWidget refresca los 3 providers en orden', () async {
    final updates = <String?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (call) async {
        if (call.method == 'updateWidget') {
          updates.add(call.arguments['android'] as String?);
        }
        return null;
      },
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
    });

    // En el entorno de test no hay sqflite real ni datos de localidad: el
    // método debe completar con valores por defecto y, aún así, refrescar
    // los tres widgets (el requisito de que no se "congele" ante un fallo).
    await actualizarHomeWidget();

    expect(
      updates,
      ['WidgetRelojProvider', 'WidgetMarcadorProvider', 'WidgetReporteProvider'],
    );
  });
}