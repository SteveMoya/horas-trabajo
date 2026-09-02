import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/data/models/rd_pay_rules.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/domain/salary/salary_engine.dart';

/// Pruebas del motor de cálculo salarial con reglas RD por defecto.
void main() {
  const salario = 30000.0;
  const reglas = RdPayRules();
  const motor = SalaryEngine(salarioMensual: salario, reglas: reglas);
  test('valor hora ordinaria correcto', () {
    expect(motor.valorHoraOrdinaria, closeTo(157.36, 0.01));
  });

  WorkSession ses(DateTime ini, DateTime fin) =>
      WorkSession(id: 1, inicio: ini, fin: fin);

  test('jornada diurna de 8h es 100% ordinaria', () {
    final r = motor.calcularRango([
      ses(DateTime(2026, 9, 1, 8), DateTime(2026, 9, 1, 16)),
    ]);
    expect(r.totalHoras, closeTo(8, 0.001));
    expect(r.ordinarias, closeTo(8, 0.001));
    expect(r.extra, closeTo(0, 0.001));
    expect(r.importeTotal, closeTo(motor.valorHoraOrdinaria * 8, 0.01));
  });

  test('hora nocturna aplica recargo +15%', () {
    final r = motor.calcularSesionUnica(
      ses(DateTime(2026, 9, 1, 20), DateTime(2026, 9, 1, 22)),
    );
    // 1h ordinaria (20-21) + 1h nocturna (21-22)
    expect(r.totalHoras, closeTo(2, 0.001));
    expect(r.importeTotal,
        closeTo(motor.valorHoraOrdinaria * (1 + reglas.factorNocturno), 0.01));
  });

  test('jornada de 10h: 8 ordinarias + 2 extras (+35%)', () {
    final r = motor.calcularRango([
      ses(DateTime(2026, 9, 1, 8), DateTime(2026, 9, 1, 18)),
    ]);
    expect(r.ordinarias, closeTo(8, 0.001));
    expect(r.extra, closeTo(2, 0.001));
    expect(r.importeTotal,
        closeTo(motor.valorHoraOrdinaria * (8 + 2 * reglas.factorExtra), 0.01));
  });

  test('fecha marcada como feriado se paga doble', () {
    final s = WorkSession(
      id: 2,
      inicio: DateTime(2026, 9, 1, 8),
      fin: DateTime(2026, 9, 1, 12),
      esFeriado: true,
    );
    final r = motor.calcularRango([s]);
    expect(r.feriadas, closeTo(4, 0.001));
    expect(r.importeTotal, closeTo(motor.valorHoraOrdinaria * 4 * 2, 0.01));
  });

  test('fecha no marcada como feriado no cuenta feriadas', () {
    final s = ses(DateTime(2026, 9, 1, 8), DateTime(2026, 9, 1, 12));
    final r = motor.calcularRango([s]);
    expect(r.feriadas, closeTo(0, 0.001));
  });
}