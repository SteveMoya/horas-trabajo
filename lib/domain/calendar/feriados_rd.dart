/// Feriados de República Dominicana según la Ley 139-97 (traslado de días
/// feriados) y sus modificaciones posteriores.
///
/// Reglas verificadas contra el calendario oficial 2026 (Ministerio de
/// Trabajo / prensa nacional), cruzando cada fecha con su día de semana:
///
/// - **Fijos** (nunca se trasladan, sin importar el día de semana en que
///   caigan): Año Nuevo, Altagracia, Independencia, Mercedes y Navidad.
///   Viernes Santo y Corpus Christi también son "fijos" en el sentido de
///   que la ley no los traslada, pero su fecha varía cada año porque se
///   calculan a partir de la Pascua.
/// - **Trasladables al lunes**: si caen martes o miércoles se mueven al
///   lunes ANTERIOR; si caen jueves o viernes se mueven al lunes
///   SIGUIENTE; si ya caen lunes, sábado o domingo, quedan igual (la ley
///   no cubre esos dos últimos casos). Aplica a: Día de Reyes, Natalicio
///   de Duarte, Día del Trabajo, Día de la Restauración y Día de la
///   Constitución.
///
/// Nota: el traslado del Día de la Restauración (16 de agosto) tiene una
/// excepción legal poco común cuando esa fecha coincide con el inicio de
/// un período constitucional (cada 4 años); esa excepción no está
/// implementada aquí — se trata siempre como trasladable.
library;

/// Un feriado de un año concreto.
class Feriado {
  const Feriado(this.fecha, this.nombre);

  final DateTime fecha;
  final String nombre;
}

class FeriadosRD {
  FeriadosRD._();

  /// Todos los feriados del año [year], ordenados por fecha.
  static List<Feriado> delAnio(int year) {
    final pascua = _domingoDePascua(year);
    final viernesSanto = pascua.subtract(const Duration(days: 2));
    final corpusChristi = pascua.add(const Duration(days: 60));

    final feriados = <Feriado>[
      Feriado(DateTime(year, 1, 1), 'Año Nuevo'),
      Feriado(DateTime(year, 1, 21), 'Nuestra Señora de la Altagracia'),
      Feriado(DateTime(year, 2, 27), 'Día de la Independencia Nacional'),
      Feriado(viernesSanto, 'Viernes Santo'),
      Feriado(corpusChristi, 'Corpus Christi'),
      Feriado(DateTime(year, 9, 24), 'Nuestra Señora de las Mercedes'),
      Feriado(DateTime(year, 12, 25), 'Navidad'),
      Feriado(_trasladarALunes(DateTime(year, 1, 6)), 'Día de Reyes'),
      Feriado(_trasladarALunes(DateTime(year, 1, 26)),
          'Natalicio de Juan Pablo Duarte'),
      Feriado(_trasladarALunes(DateTime(year, 5, 1)), 'Día del Trabajo'),
      Feriado(
          _trasladarALunes(DateTime(year, 8, 16)), 'Día de la Restauración'),
      Feriado(
          _trasladarALunes(DateTime(year, 11, 6)), 'Día de la Constitución'),
    ];
    feriados.sort((a, b) => a.fecha.compareTo(b.fecha));
    return feriados;
  }

  /// El feriado que cae en [fecha] (comparando solo año/mes/día), o `null`
  /// si esa fecha no es feriado.
  static Feriado? feriadoEn(DateTime fecha) {
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    for (final f in delAnio(fecha.year)) {
      if (f.fecha.year == dia.year &&
          f.fecha.month == dia.month &&
          f.fecha.day == dia.day) {
        return f;
      }
    }
    return null;
  }

  /// Ley 139-97: martes/miércoles -> lunes anterior; jueves/viernes ->
  /// lunes siguiente. Lunes, sábado y domingo quedan sin cambios.
  static DateTime _trasladarALunes(DateTime fecha) {
    switch (fecha.weekday) {
      case DateTime.tuesday:
        return fecha.subtract(const Duration(days: 1));
      case DateTime.wednesday:
        return fecha.subtract(const Duration(days: 2));
      case DateTime.thursday:
        return fecha.add(const Duration(days: 4));
      case DateTime.friday:
        return fecha.add(const Duration(days: 3));
      default:
        return fecha;
    }
  }

  /// Domingo de Pascua (calendario gregoriano) vía el algoritmo de
  /// Meeus/Jones/Butcher.
  static DateTime _domingoDePascua(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final n = h + l - 7 * m + 114;
    final mes = n ~/ 31;
    final dia = (n % 31) + 1;
    return DateTime(year, mes, dia);
  }
}
