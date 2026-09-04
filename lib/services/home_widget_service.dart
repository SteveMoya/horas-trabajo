import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/data/repositories/work_session_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Nombres de los `HomeWidgetProvider` nativos (android/.../Widget*.kt) —
/// deben coincidir exactamente con el `android:name` de cada receiver:
/// reloj, marcador y reporte.
const _kProviders = [
  'WidgetRelojProvider',
  'WidgetMarcadorProvider',
  'WidgetReporteProvider',
];

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
    } else if (uri.host == 'marcaralternar') {
      // Botón único del widget Marcador: si hay jornada en curso la cierra,
      // si no, abre una nueva.
      final activa = await sessions.obtenerEnProgreso();
      if (activa == null) {
        await sessions.insertar(WorkSession(id: 0, inicio: DateTime.now()));
      } else {
        await sessions.actualizar(activa.copyWith(fin: DateTime.now()));
      }
    }
    await actualizarHomeWidget();
  } catch (e) {
    debugPrint('homeWidgetInteractivityCallback falló: $e');
  }
}

/// Refresca los 3 widgets de pantalla de inicio con el estado actual y con
/// las horas de hoy, de la semana y la fecha en español (para el widget
/// reloj). Cada widget lee de estas claves compartidas vía SharedPreferences.
/// Se llama tanto desde el callback headless de arriba como desde AppState
/// al marcar/editar/eliminar sesiones, para que los widgets nunca queden
/// desactualizados sin importar desde dónde se hizo el cambio.
///
/// IMPORTANTE: es a prueba de fallas — lee de la base primero, y aún si
/// cualquier parte falla (locale de fecha, un guardado, una BD), los
/// providers se actualizan igualmente con lo último que se pudo leer. Así un
/// fallo parcial nunca deja el widget "estático" sin reflejar el marcado.
Future<void> actualizarHomeWidget() async {
  // Valores por defecto: si la BD falla, al menos se publican estos.
  var enCurso = false;
  var estado = 'Fuera de la jornada';
  var inicioMillis = '';
  var hoyHoras = '0.00 h';
  var semanaHoras = '0.00 h';
  var fecha = '';

  try {
    // Este isolate headless nunca pasa por main.dart, así que Fmt.horaCorta
    // (DateFormat con locale 'es') lanza LocaleDataException si no se
    // inicializan los datos de localización. Llamarlo de nuevo desde la app
    // principal (donde ya está inicializado) es inofensivo.
    try {
      await initializeDateFormatting('es');
    } catch (_) {/* datos de localidad no disponibles */}

    final repo = WorkSessionRepository();
    final activa = await repo.obtenerEnProgreso();
    final sesiones = await repo.obtenerTodas();

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana = inicioHoy.subtract(Duration(days: ahora.weekday - 1));

    enCurso = activa != null;
    estado = enCurso
        ? 'En curso desde ${Fmt.horaCorta(activa.inicio)}'
        : 'Fuera de la jornada';
    // El widget nativo arma su propio estado/cronómetro con esta hora de
    // inicio (ver WidgetAcciones.kt) — vacío significa "sin jornada activa".
    inicioMillis = enCurso ? activa.inicio.millisecondsSinceEpoch.toString() : '';
    hoyHoras = Fmt.horas(_horasDesde(sesiones, inicioHoy, ahora));
    semanaHoras = Fmt.horas(_horasDesde(sesiones, inicioSemana, ahora));
    try {
      // Fecha en español para el widget reloj. Se aísla por si el locale
      // 'es' no está disponible en el isolate: no debe bloquear el refresco.
      fecha = DateFormat('EEEE d \'de\' MMMM', 'es').format(ahora);
    } catch (_) {/* fecha opcional; el widget usa el estado igual */}
  } catch (e) {
    debugPrint('actualizarHomeWidget · lectura falló: $e');
  }

  // Guardado de datos — cada clave de forma aislada.
  final datos = <String, String>{
    'en_curso': enCurso ? '1' : '0',
    'estado': estado,
    'inicio_millis': inicioMillis,
    'hoy_horas': hoyHoras,
    'semana_horas': semanaHoras,
    if (fecha.isNotEmpty) 'fecha': fecha,
  };
  for (final entry in datos.entries) {
    try {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    } catch (e) {
      debugPrint('actualizarHomeWidget · guardar ${entry.key} falló: $e');
    }
  }

  // Actualización de los 3 providers — SIEMPRE se intenta, de forma
  // independiente, aunque algún guardado anterior haya fallado.
  for (final provider in _kProviders) {
    try {
      await HomeWidget.updateWidget(androidName: provider);
    } catch (e) {
      debugPrint('actualizarHomeWidget · update $provider falló: $e');
    }
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