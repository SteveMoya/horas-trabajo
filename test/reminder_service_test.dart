import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/services/reminder_service.dart';

void main() {
  final service = ReminderService();

  test('promedioMinutosDelDia calcula el promedio de la hora del día', () {
    final fechas = [
      DateTime(2026, 1, 1, 9, 0), // 540 min
      DateTime(2026, 1, 2, 9, 10), // 550 min
      DateTime(2026, 1, 3, 8, 50), // 530 min
    ];
    // promedio = (540+550+530)/3 = 540
    expect(service.promedioMinutosDelDia(fechas), 540);
  });

  test('sumarMinutos da la vuelta después de medianoche', () {
    // 23:50 + 30 min -> 00:20 del día siguiente (20 min desde medianoche).
    expect(service.sumarMinutos(23 * 60 + 50, 30), 20);
    // Caso normal, sin dar la vuelta.
    expect(service.sumarMinutos(9 * 60, 45), 9 * 60 + 45);
  });

  test('recalcularYProgramar no lanza con menos del mínimo de sesiones', () async {
    final sesiones = [
      WorkSession(id: 1, inicio: DateTime(2026, 1, 1, 9), fin: DateTime(2026, 1, 1, 17)),
    ];
    await expectLater(service.recalcularYProgramar(sesiones), completes);
  });

  test('recalcularYProgramar no lanza con suficientes sesiones cerradas', () async {
    final sesiones = List.generate(
      6,
      (i) => WorkSession(
        id: i,
        inicio: DateTime(2026, 1, i + 1, 9),
        fin: DateTime(2026, 1, i + 1, 17),
      ),
    );
    await expectLater(service.recalcularYProgramar(sesiones), completes);
  });
}
