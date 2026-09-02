/// Perfil del trabajador: datos necesarios para el cálculo salarial.
class EmployeeProfile {
  const EmployeeProfile({
    this.nombre = '',
    this.salarioMensual = 0.0,
    this.moneda = 'RD\$',
    this.esExentoRetenciones = false,
  });

  final String nombre;

  /// Salario bruto mensual (en pesos dominicanos por defecto).
  final double salarioMensual;

  /// Símbolo o código de moneda para mostrar importes.
  final String moneda;

  /// Flag informativo (no implementa retenciones ISR/TSS en esta versión).
  final bool esExentoRetenciones;

  bool get perfilCompleto =>
      nombre.isNotEmpty && salarioMensual > 0;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'salarioMensual': salarioMensual,
        'moneda': moneda,
        'esExentoRetenciones': esExentoRetenciones,
      };

  factory EmployeeProfile.fromJson(Map<String, dynamic> j) => EmployeeProfile(
        nombre: (j['nombre'] as String?) ?? '',
        salarioMensual: (j['salarioMensual'] as num?)?.toDouble() ?? 0,
        moneda: (j['moneda'] as String?) ?? 'RD\$',
        esExentoRetenciones: (j['esExentoRetenciones'] as bool?) ?? false,
      );

  EmployeeProfile copyWith({
    String? nombre,
    double? salarioMensual,
    String? moneda,
    bool? esExentoRetenciones,
  }) =>
      EmployeeProfile(
        nombre: nombre ?? this.nombre,
        salarioMensual: salarioMensual ?? this.salarioMensual,
        moneda: moneda ?? this.moneda,
        esExentoRetenciones:
            esExentoRetenciones ?? this.esExentoRetenciones,
      );
}