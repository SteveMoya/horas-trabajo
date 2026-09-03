import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/data/repositories/work_session_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Nombre del `HomeWidgetProvider` nativo (android/app/src/main/kotlin/.../
/// MarcadorWidgetProvider.kt) — debe coincidir exactamente.
const _kProviderName = 'MarcadorWidgetProvider';

/// Callback headless: se ejecuta en un isolate de Flutter nuevo cuando se
/// toca un botón del widget de pantalla de inicio, sin abrir la app.
/// Igual que el isolate de `background_service.dart`, habla directo con el
/// repositorio — no hay `AppState` disponible aquí.
@pragma('vm:entry-point')
Future<void> homeWidgetInteractivityCallback(Uri? uri) async {
  if (uri == null) return;
  try {
    // El engine headless que crea el paquete home_widget no registra los
    // plugins automáticamente (mismo caso que el isolate de geocerca en
    // background_service.dart); sin esto, sqflite lanza
    // MissingPluginException silenciosamente dentro de este try/catch.
    DartPluginRegistrant.ensureInitialized();
    final sessions = WorkSessionRepository();
    // Uri.host normaliza a minúsculas (RFC 3986); comparar en minúsculas
    // evita que un cambio de mayúsculas en el lado nativo rompa esto de
    // nuevo en silencio.
    if (uri.host == 'marcarentrada') {
      if (await sessions.obtenerEnProgreso() == null) {
        await sessions.insertar(WorkSession(id: 0, inicio: DateTime.now()));
      }
    } else if (uri.host == 'marcarsalida') {
      final activa = await sessions.obtenerEnProgreso();
      if (activa != null) {
        await sessions.actualizar(activa.copyWith(fin: DateTime.now()));
      }
    }
    await actualizarHomeWidget();
  } catch (e) {
    debugPrint('homeWidgetInteractivityCallback falló: $e');
  }
}

/// Refresca el texto del widget con el estado actual. Se llama tanto desde
/// el callback headless de arriba como desde AppState al marcar entrada/
/// salida dentro de la propia app, para que el widget nunca quede
/// desactualizado sin importar desde dónde se marcó.
Future<void> actualizarHomeWidget() async {
  try {
    // Este isolate headless nunca pasa por main.dart, así que Fmt.horaCorta
    // (DateFormat con locale 'es') lanza LocaleDataException si no se
    // inicializan los datos de localización primero. Llamarlo de nuevo
    // desde la app principal (donde ya está inicializado) es inofensivo.
    try {
      await initializeDateFormatting('es');
    } catch (_) {/* datos de localidad no disponibles */}

    final activa = await WorkSessionRepository().obtenerEnProgreso();
    await HomeWidget.saveWidgetData<String>(
      'estado',
      activa == null
          ? 'Fuera de la jornada'
          : 'En curso desde ${Fmt.horaCorta(activa.inicio)}',
    );
    await HomeWidget.updateWidget(androidName: _kProviderName);
  } catch (e) {
    debugPrint('actualizarHomeWidget falló: $e');
  }
}
