import 'package:flutter/foundation.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/services/notifications_service.dart';

/// Calcula la "hora típica" de entrada/salida a partir del historial
/// reciente y programa (o cancela) los recordatorios inteligentes.
///
/// Limitación conocida: la notificación programada no puede verificar en
/// el instante del disparo si esa entrada/salida ya se marcó ese día — es
/// un recordatorio best-effort, no una alerta perfecta. Evitar esto
/// requeriría infraestructura de fondo más pesada (p. ej. WorkManager) que
/// no se justifica para este alcance.
class ReminderService {
  /// Mínimo de sesiones cerradas para confiar en el patrón calculado.
  static const minimoSesiones = 5;

  static const _minutosDespuesEntrada = 45;
  static const _minutosDespuesSalida = 15;

  /// Recalcula el horario típico con [sesiones] y reprograma los
  /// recordatorios. Si no hay suficientes sesiones cerradas, cancela
  /// cualquier recordatorio existente en vez de usar datos poco confiables.
  Future<void> recalcularYProgramar(List<WorkSession> sesiones) async {
    final cerradas = sesiones.where((s) => s.fin != null).toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));
    final recientes = cerradas.take(14).toList();

    if (recientes.length < minimoSesiones) {
      await NotificationsService.cancelarRecordatorios();
      return;
    }

    final entradaMin = promedioMinutosDelDia(recientes.map((s) => s.inicio));
    final salidaMin = promedioMinutosDelDia(recientes.map((s) => s.fin!));

    final entrada = sumarMinutos(entradaMin, _minutosDespuesEntrada);
    final salida = sumarMinutos(salidaMin, _minutosDespuesSalida);

    await NotificationsService.programarRecordatorioDiario(
      id: NotificationsService.idRecordatorioEntrada,
      title: '⏰ ¿Olvidaste marcar la entrada?',
      body: 'Según tu horario habitual, ya deberías haber entrado.',
      hora: entrada ~/ 60,
      minuto: entrada % 60,
    );
    await NotificationsService.programarRecordatorioDiario(
      id: NotificationsService.idRecordatorioSalida,
      title: '⏰ ¿Olvidaste marcar la salida?',
      body: 'Según tu horario habitual, ya deberías haber salido.',
      hora: salida ~/ 60,
      minuto: salida % 60,
    );
  }

  /// Promedio (en minutos desde medianoche) de la hora del día de [fechas].
  @visibleForTesting
  int promedioMinutosDelDia(Iterable<DateTime> fechas) {
    final minutos = fechas.map((d) => d.hour * 60 + d.minute).toList();
    final promedio = minutos.reduce((a, b) => a + b) / minutos.length;
    return promedio.round();
  }

  @visibleForTesting
  int sumarMinutos(int minutosDelDia, int extra) =>
      (minutosDelDia + extra) % (24 * 60);
}
