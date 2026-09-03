/// Tipo de ausencia registrada manualmente (no afecta el cálculo salarial
/// de las sesiones trabajadas; es solo registro/calendario).
enum TipoAusencia {
  vacacion,
  permiso,
  licencia;

  String get etiqueta => switch (this) {
        TipoAusencia.vacacion => 'Vacaciones',
        TipoAusencia.permiso => 'Permiso',
        TipoAusencia.licencia => 'Licencia',
      };
}

/// Un período de vacaciones, permiso o licencia.
class Ausencia {
  const Ausencia({
    required this.id,
    required this.fechaInicio,
    required this.fechaFin,
    required this.tipo,
    this.nota = '',
  });

  final int id;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final TipoAusencia tipo;
  final String nota;

  Map<String, dynamic> toMap() => {
        'id': id,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'tipo': tipo.name,
        'nota': nota,
      };

  factory Ausencia.fromMap(Map<String, dynamic> m) => Ausencia(
        id: (m['id'] as num).toInt(),
        fechaInicio: DateTime.parse(m['fechaInicio'] as String),
        fechaFin: DateTime.parse(m['fechaFin'] as String),
        tipo: TipoAusencia.values.firstWhere(
          (t) => t.name == m['tipo'],
          orElse: () => TipoAusencia.permiso,
        ),
        nota: (m['nota'] as String?) ?? '',
      );

  Ausencia copyWith({
    int? id,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    TipoAusencia? tipo,
    String? nota,
  }) =>
      Ausencia(
        id: id ?? this.id,
        fechaInicio: fechaInicio ?? this.fechaInicio,
        fechaFin: fechaFin ?? this.fechaFin,
        tipo: tipo ?? this.tipo,
        nota: nota ?? this.nota,
      );
}
