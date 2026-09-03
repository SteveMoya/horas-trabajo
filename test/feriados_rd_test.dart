import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/domain/calendar/feriados_rd.dart';

void main() {
  // Valores verificados contra el calendario oficial 2026 (Ministerio de
  // Trabajo / prensa nacional): qué feriados se movieron y cuáles no.
  DateTime fechaDe(List<Feriado> feriados, String nombre) =>
      feriados.firstWhere((f) => f.nombre == nombre).fecha;

  test('feriados fijos de 2026 no se trasladan aunque caigan entre semana', () {
    final feriados = FeriadosRD.delAnio(2026);

    expect(fechaDe(feriados, 'Año Nuevo'), DateTime(2026, 1, 1));
    expect(
      fechaDe(feriados, 'Nuestra Señora de la Altagracia'),
      DateTime(2026, 1, 21), // cae miércoles y no se mueve
    );
    expect(
      fechaDe(feriados, 'Día de la Independencia Nacional'),
      DateTime(2026, 2, 27), // cae viernes y no se mueve
    );
    expect(
      fechaDe(feriados, 'Nuestra Señora de las Mercedes'),
      DateTime(2026, 9, 24), // cae jueves y no se mueve
    );
    expect(fechaDe(feriados, 'Navidad'), DateTime(2026, 12, 25));
  });

  test('Pascua 2026 calculada correctamente (Viernes Santo y Corpus Christi)', () {
    final feriados = FeriadosRD.delAnio(2026);

    expect(fechaDe(feriados, 'Viernes Santo'), DateTime(2026, 4, 3));
    expect(fechaDe(feriados, 'Corpus Christi'), DateTime(2026, 6, 4));
  });

  test('feriados trasladables de 2026 se mueven al lunes correcto', () {
    final feriados = FeriadosRD.delAnio(2026);

    // 6 de enero cae martes -> lunes anterior.
    expect(fechaDe(feriados, 'Día de Reyes'), DateTime(2026, 1, 5));
    // 1 de mayo cae viernes -> lunes siguiente.
    expect(fechaDe(feriados, 'Día del Trabajo'), DateTime(2026, 5, 4));
    // 6 de noviembre cae viernes -> lunes siguiente.
    expect(fechaDe(feriados, 'Día de la Constitución'), DateTime(2026, 11, 9));
  });

  test('feriado que ya cae domingo no se traslada (Restauración 2026)', () {
    final feriados = FeriadosRD.delAnio(2026);
    expect(
      fechaDe(feriados, 'Día de la Restauración'),
      DateTime(2026, 8, 16),
    );
  });

  test('feriadoEn encuentra el feriado exacto y null en un día normal', () {
    expect(FeriadosRD.feriadoEn(DateTime(2026, 12, 25))?.nombre, 'Navidad');
    expect(FeriadosRD.feriadoEn(DateTime(2026, 3, 10)), isNull);
  });
}
