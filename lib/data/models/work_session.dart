/// Una jornada/sesión de trabajo: desde el marcardor de entrada hasta el de salida.
class WorkSession {
  const WorkSession({
    required this.id,
    required this.inicio,
    this.fin,
    this.latitud,
    this.longitud,
    this.nota = '',
    this.esFeriado = false,
    this.esDescansoSemanal = false,
  });

  final int id;
  final DateTime inicio;
  final DateTime? fin;

  /// Ubicación GPS del marcardor de entrada (opcional).
  final double? latitud;
  final double? longitud;
  final String nota;

  /// Marca manual: la jornada cayó en un día feriado.
  final bool esFeriado;

  /// Marca manual: la jornada fue en el día de descanso semanal.
  final bool esDescansoSemanal;

  bool get enProgreso => fin == null;

  Duration get duracion {
    if (fin == null) return Duration.zero;
    final d = fin!.difference(inicio);
    return d.isNegative ? Duration.zero : d;
  }

  WorkSession copyWith({
    int? id,
    DateTime? inicio,
    DateTime? fin,
    double? latitud,
    double? longitud,
    bool clearUbicacion = false,
    String? nota,
    bool? esFeriado,
    bool? esDescansoSemanal,
  }) {
    return WorkSession(
      id: id ?? this.id,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      latitud: clearUbicacion ? null : (latitud ?? this.latitud),
      longitud: clearUbicacion ? null : (longitud ?? this.longitud),
      nota: nota ?? this.nota,
      esFeriado: esFeriado ?? this.esFeriado,
      esDescansoSemanal: esDescansoSemanal ?? this.esDescansoSemanal,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'inicio': inicio.toIso8601String(),
        'fin': fin?.toIso8601String(),
        'latitud': latitud,
        'longitud': longitud,
        'nota': nota,
        'esFeriado': esFeriado ? 1 : 0,
        'esDescansoSemanal': esDescansoSemanal ? 1 : 0,
      };

  factory WorkSession.fromMap(Map<String, dynamic> m) => WorkSession(
        id: (m['id'] as num).toInt(),
        inicio: DateTime.parse(m['inicio'] as String),
        fin: m['fin'] == null ? null : DateTime.parse(m['fin'] as String),
        latitud: (m['latitud'] as num?)?.toDouble(),
        longitud: (m['longitud'] as num?)?.toDouble(),
        nota: (m['nota'] as String?) ?? '',
        esFeriado: (m['esFeriado'] as num?) == 1,
        esDescansoSemanal: (m['esDescansoSemanal'] as num?) == 1,
      );
}