import 'package:intl/intl.dart';

/// Utilidades de formato de fechas, horas y moneda (es-DO / RD$).
class Fmt {
  static final NumberFormat _moneda = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$',
    decimalDigits: 2,
  );

  static final NumberFormat _horas = NumberFormat('0.00');
  static final DateFormat _fechaCorta = DateFormat('EEE d MMM', 'es');
  static final DateFormat _fechaLarga = DateFormat('EEEE, d \'de\' MMMM \'de\' yyyy', 'es');
  static final DateFormat _hora = DateFormat('hh:mm a', 'es');
  static final DateFormat _fechaExacta = DateFormat('d MMM yyyy, hh:mm a', 'es');

  /// Formatea un monto en pesos dominicanos (RD$1,234.50).
  static String moneda(double valor) => _moneda.format(valor);

  /// Formatea horas con dos decimales (8.50).
  static String horas(double horas) => '${_horas.format(horas)} h';

  static String fechaCorta(DateTime d) => _fechaCorta.format(d);
  static String fechaLarga(DateTime d) => _fechaLarga.format(d);
  static String horaCorta(DateTime d) => _hora.format(d);
  static String fechaExacta(DateTime d) => _fechaExacta.format(d);

  static String duracion(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (d.inSeconds <= 0) return '--:--';
    final mm = m.toString().padLeft(2, '0');
    if (h <= 0) return '$mm:${s.toString().padLeft(2, '0')}';
    return '$h:$mm';
  }

  /// Formatea como "8h 30m".
  static String duracionExtendida(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0 && m <= 0) return '0m';
    if (h <= 0) return '${m}m';
    if (m <= 0) return '${h}h';
    return '${h}h ${m}m';
  }
}