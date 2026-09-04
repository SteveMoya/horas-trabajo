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

/// Refresca el widget de pantalla de inicio con el estado actual, y con
/// las horas de hoy y de la semana para su variante grande. Se llama
/// tanto desde el callback headless de arriba como desde AppState al
/// marcar entrada/salida dentro de la propia app, para que el widget
/// nunca quede desactualizado sin importar desde dónde se marcó.
Future<void> actualizarHomeWidget() async {
  try {
    // Este isolate headless nunca pasa por main.dart, así que Fmt.horaCorta
    // (DateFormat con locale 'es') lanza LocaleDataException si no se
    // inicializan los datos de localización primero. Llamarlo de nuevo
    // desde la app principal (donde ya está inicializado) es inofensivo.
    try {
      await initializeDateFormatting('es');
    } catch (_) {/* datos de localidad no disponibles */}

    final repo = WorkSessionRepository();
    final activa = await repo.obtenerEnProgreso();
    final sesiones = await repo.obtenerTodas();

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana = inicioHoy.subtract(Duration(days: ahora.weekday - 1));

    await HomeWidget.saveWidgetData<String>(
      'estado',
      activa == null
          ? 'Fuera de la jornada'
          : 'En curso desde ${Fmt.horaCorta(activa.inicio)}',
    );
    // El widget nativo arma su propio Chronometer con esta hora de inicio
    // (ver MarcadorWidgetProvider.kt) — vacío significa "sin jornada activa".
    await HomeWidget.saveWidgetData<String>(
      'inicio_millis',
      activa == null ? '' : activa.inicio.millisecondsSinceEpoch.toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'hoy_horas',
      Fmt.horas(_horasDesde(sesiones, inicioHoy, ahora)),
    );
    await HomeWidget.saveWidgetData<String>(
      'semana_horas',
      Fmt.horas(_horasDesde(sesiones, inicioSemana, ahora)),
    );
    await HomeWidget.updateWidget(androidName: _kProviderName);
  } catch (e) {
    debugPrint('actualizarHomeWidget falló: $e');
  }
}

/// Suma las horas trabajadas en sesiones que empezaron en o después de
/// [desde] — la sesión en curso (sin `fin`) cuenta hasta [ahora].
double _horasDesde(List<WorkSession> sesiones, DateTime desde, DateTime ahora) {
  var total = 0.0;
  for (final s in sesiones) {
    if (s.inicio.isBefore(desde)) continue;
    total += (s.fin ?? ahora).difference(s.inicio).inMinutes / 60.0;
  }
  return total;
}
