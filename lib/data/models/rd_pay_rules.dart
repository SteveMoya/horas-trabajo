/// Reglas de pago del Código de Trabajo de República Dominicana (Ley 16-92).
///
/// Valores por defecto tomados de guías de nómina RD vigentes (2026).
/// TODOS estos valores son editables desde Ajustes, para poder validar
/// contra el texto oficial aplicable en cada caso.
class RdPayRules {
  const RdPayRules({
    this.ordinariaDiaHoras = 8,
    this.ordinariaSemanaHoras = 44,
    this.excesoTopeHoras = 68,
    this.recargoExtraPct = 35,
    this.recargoExcesoPct = 100,
    this.recargoNocturnoPct = 15,
    this.recargoFeriadoPct = 100,
    this.recargoDescansoPct = 100,
    this.nocturnoInicioHora = 21, // 9:00 p. m.
    this.nocturnoFinHora = 7, // 7:00 a. m.
    this.diasPorMes = 23.83,
  });

  /// Máximo de horas ordinarias por día (jornada diaria).
  final int ordinariaDiaHoras;

  /// Máximo de horas ordinarias por semana (jornada semanal).
  final int ordinariaSemanaHoras;

  /// Umbral semanal a partir del cual las horas extras pagan el mayor recargo.
  final int excesoTopeHoras;

  /// Recargo (%) de horas extraordinarias regulares (sobre la ordinaria).
  final double recargoExtraPct;

  /// Recargo (%) por exceso semanal (más de [excesoTopeHoras]).
  final double recargoExcesoPct;

  /// Recargo (%) por jornada nocturna.
  final double recargoNocturnoPct;

  /// Recargo (%) por trabajar en día feriado.
  final double recargoFeriadoPct;

  /// Recargo (%) por trabajar en día de descanso semanal.
  final double recargoDescansoPct;

  /// Inicio (hora 0-23) de la franja nocturna.
  final int nocturnoInicioHora;

  /// Fin (hora 0-23) de la franja nocturna.
  final int nocturnoFinHora;

  /// Divisor estándar de RD para obtener el salario diario promedio.
  /// Salario diario = salario mensual / diasPorMes.
  final double diasPorMes;

  bool get _nocturnoEnvuelveMedianoche =>
      nocturnoInicioHora > nocturnoFinHora;

  /// Indica si la [hora] (0-23) cae dentro de la franja nocturna configurada.
  bool esHoraNocturna(int hora) {
    if (_nocturnoEnvuelveMedianoche) {
      return hora >= nocturnoInicioHora || hora < nocturnoFinHora;
    }
    return hora >= nocturnoInicioHora && hora < nocturnoFinHora;
  }

  double get factorExtra => 1 + recargoExtraPct / 100;
  double get factorExceso => 1 + recargoExcesoPct / 100;
  double get factorNocturno => 1 + recargoNocturnoPct / 100;
  double get factorFeriado => 1 + recargoFeriadoPct / 100;
  double get factorDescanso => 1 + recargoDescansoPct / 100;

  /// Salario bruto por hora ordinaria a partir del salario mensual.
  double valorHoraOrdinaria(double salarioMensual) =>
      salarioMensual / diasPorMes / ordinariaDiaHoras;

  RdPayRules copyWith({
    int? ordinariaDiaHoras,
    int? ordinariaSemanaHoras,
    int? excesoTopeHoras,
    double? recargoExtraPct,
    double? recargoExcesoPct,
    double? recargoNocturnoPct,
    double? recargoFeriadoPct,
    double? recargoDescansoPct,
    int? nocturnoInicioHora,
    int? nocturnoFinHora,
    double? diasPorMes,
  }) {
    return RdPayRules(
      ordinariaDiaHoras: ordinariaDiaHoras ?? this.ordinariaDiaHoras,
      ordinariaSemanaHoras: ordinariaSemanaHoras ?? this.ordinariaSemanaHoras,
      excesoTopeHoras: excesoTopeHoras ?? this.excesoTopeHoras,
      recargoExtraPct: recargoExtraPct ?? this.recargoExtraPct,
      recargoExcesoPct: recargoExcesoPct ?? this.recargoExcesoPct,
      recargoNocturnoPct: recargoNocturnoPct ?? this.recargoNocturnoPct,
      recargoFeriadoPct: recargoFeriadoPct ?? this.recargoFeriadoPct,
      recargoDescansoPct: recargoDescansoPct ?? this.recargoDescansoPct,
      nocturnoInicioHora: nocturnoInicioHora ?? this.nocturnoInicioHora,
      nocturnoFinHora: nocturnoFinHora ?? this.nocturnoFinHora,
      diasPorMes: diasPorMes ?? this.diasPorMes,
    );
  }

  Map<String, dynamic> toJson() => {
        'ordinariaDiaHoras': ordinariaDiaHoras,
        'ordinariaSemanaHoras': ordinariaSemanaHoras,
        'excesoTopeHoras': excesoTopeHoras,
        'recargoExtraPct': recargoExtraPct,
        'recargoExcesoPct': recargoExcesoPct,
        'recargoNocturnoPct': recargoNocturnoPct,
        'recargoFeriadoPct': recargoFeriadoPct,
        'recargoDescansoPct': recargoDescansoPct,
        'nocturnoInicioHora': nocturnoInicioHora,
        'nocturnoFinHora': nocturnoFinHora,
        'diasPorMes': diasPorMes,
      };

  factory RdPayRules.fromJson(Map<String, dynamic> j) => RdPayRules(
        ordinariaDiaHoras: (j['ordinariaDiaHoras'] as num?)?.toInt() ?? 8,
        ordinariaSemanaHoras:
            (j['ordinariaSemanaHoras'] as num?)?.toInt() ?? 44,
        excesoTopeHoras: (j['excesoTopeHoras'] as num?)?.toInt() ?? 68,
        recargoExtraPct: (j['recargoExtraPct'] as num?)?.toDouble() ?? 35,
        recargoExcesoPct: (j['recargoExcesoPct'] as num?)?.toDouble() ?? 100,
        recargoNocturnoPct: (j['recargoNocturnoPct'] as num?)?.toDouble() ?? 15,
        recargoFeriadoPct: (j['recargoFeriadoPct'] as num?)?.toDouble() ?? 100,
        recargoDescansoPct:
            (j['recargoDescansoPct'] as num?)?.toDouble() ?? 100,
        nocturnoInicioHora: (j['nocturnoInicioHora'] as num?)?.toInt() ?? 21,
        nocturnoFinHora: (j['nocturnoFinHora'] as num?)?.toInt() ?? 7,
        diasPorMes: (j['diasPorMes'] as num?)?.toDouble() ?? 23.83,
      );
}