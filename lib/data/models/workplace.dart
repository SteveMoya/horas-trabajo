import 'package:flutter/material.dart';

/// El lugar de trabajo configurado (geocerca) para la vigilancia de llegada/salida.
class Workplace {
  const Workplace({
    required this.id,
    required this.latitud,
    required this.longitud,
    this.nombre = 'Mi lugar de trabajo',
    this.radioMetros = 150,
    required this.creadoEn,
  });

  final int id;
  final double latitud;
  final double longitud;
  final String nombre;

  /// Radio de la geocerca en metros.
  final double radioMetros;
  final DateTime creadoEn;

  /// LatLng para marcar en el mapa (si se agregara visualización).
  Offset get center => Offset(latitud, longitud);

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitud': latitud,
        'longitud': longitud,
        'nombre': nombre,
        'radioMetros': radioMetros,
        'creadoEn': creadoEn.toIso8601String(),
      };

  factory Workplace.fromJson(Map<String, dynamic> j) => Workplace(
        id: (j['id'] as num).toInt(),
        latitud: (j['latitud'] as num).toDouble(),
        longitud: (j['longitud'] as num).toDouble(),
        nombre: (j['nombre'] as String?) ?? 'Mi lugar de trabajo',
        radioMetros: (j['radioMetros'] as num?)?.toDouble() ?? 150,
        creadoEn: DateTime.parse(j['creadoEn'] as String),
      );

  Workplace copyWith({
    int? id,
    double? latitud,
    double? longitud,
    String? nombre,
    double? radioMetros,
    DateTime? creadoEn,
  }) =>
      Workplace(
        id: id ?? this.id,
        latitud: latitud ?? this.latitud,
        longitud: longitud ?? this.longitud,
        nombre: nombre ?? this.nombre,
        radioMetros: radioMetros ?? this.radioMetros,
        creadoEn: creadoEn ?? this.creadoEn,
      );
}