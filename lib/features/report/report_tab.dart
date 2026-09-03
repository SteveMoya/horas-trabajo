import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/core/widgets/animated_tap_scale.dart';
import 'package:horas_trabajo/core/widgets/staggered_fade_in.dart';
import 'package:horas_trabajo/domain/salary/salary_engine.dart';
import 'package:horas_trabajo/services/backup_service.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

enum _Periodo { semana, mes }

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  _Periodo _periodo = _Periodo.semana;
  bool _exportando = false;

  (DateTime, DateTime) _rango(DateTime hoy) {
    if (_periodo == _Periodo.semana) {
      final weekday = hoy.weekday;
      final lunes = hoy.subtract(Duration(days: weekday - 1));
      return (
        DateTime(lunes.year, lunes.month, lunes.day),
        lunes.add(const Duration(days: 7)),
      );
    }
    return (
      DateTime(hoy.year, hoy.month, 1),
      DateTime(hoy.year, hoy.month + 1, 1),
    );
  }

  String _tituloPeriodo(DateTime desde, DateTime hasta) {
    if (_periodo == _Periodo.semana) {
      final ultimoDia = hasta.subtract(const Duration(days: 1));
      return 'Nómina semanal: ${Fmt.fechaCorta(desde)} - ${Fmt.fechaCorta(ultimoDia)}';
    }
    return 'Nómina mensual: ${Fmt.mesAnio(desde)}';
  }

  Future<void> _exportarPdf(PeriodPayReport report, DateTime desde, DateTime hasta) async {
    if (_exportando) return;
    setState(() => _exportando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupService().exportarPdf(
        report,
        titulo: _tituloPeriodo(desde, hasta),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo exportar el PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hoy = DateTime.now();
    final (desde, hasta) = _rango(hoy);
    final report = app.motor.calcularRango(app.sesiones, desde: desde, hasta: hasta);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte'),
        actions: [
          AnimatedTapScale(
            child: IconButton(
              tooltip: 'Exportar PDF',
              icon: _exportando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              onPressed: _exportando ? null : () => _exportarPdf(report, desde, hasta),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<_Periodo>(
            segments: const [
              ButtonSegment(
                value: _Periodo.semana,
                label: Text('Semana'),
                icon: Icon(Icons.view_week),
              ),
              ButtonSegment(
                value: _Periodo.mes,
                label: Text('Mes'),
                icon: Icon(Icons.calendar_month),
              ),
            ],
            selected: {_periodo},
            onSelectionChanged: (s) => setState(() => _periodo = s.first),
          ),
          const SizedBox(height: 16),
          StaggeredFadeIn(index: 0, child: _TarjetaTotales(report: report)),
          const SizedBox(height: 16),
          StaggeredFadeIn(
            index: 1,
            child: _TarjetaGraficoDias(sesiones: report.sesiones, desde: desde, hasta: hasta),
          ),
          const SizedBox(height: 16),
          StaggeredFadeIn(
            index: 2,
            child: _TarjetaGraficoCategorias(lineas: report.lineasConsolidadas),
          ),
          const SizedBox(height: 16),
          StaggeredFadeIn(index: 3, child: _TarjetaDesglose(lineas: report.lineasConsolidadas)),
          const SizedBox(height: 16),
          const StaggeredFadeIn(index: 4, child: _NotaLegal()),
        ],
      ),
    );
  }
}

class _TarjetaTotales extends StatelessWidget {
  const _TarjetaTotales({required this.report});

  final PeriodPayReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Horas y pago',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Metrica(
                    titulo: 'Horas',
                    valor: Fmt.horas(report.totalHoras),
                    color: scheme.primary,
                    icon: Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _Metrica(
                    titulo: 'A pagar',
                    valor: Fmt.moneda(report.importeTotal),
                    color: scheme.tertiary,
                    icon: Icons.payments,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _Fila('Ordinarias', Fmt.horas(report.ordinarias), scheme.primary),
            _Fila('Extras +35%', Fmt.horas(report.extra), scheme.secondary),
            _Fila('Exceso +100%', Fmt.horas(report.exceso), scheme.error),
            _Fila('Nocturnas', Fmt.horas(report.nocturnas), scheme.tertiary),
            _Fila('Feriado/Descanso', Fmt.horas(report.feriadas), scheme.secondary),
          ],
        ),
      ),
    );
  }
}

class _TarjetaDesglose extends StatelessWidget {
  const _TarjetaDesglose({required this.lineas});

  final List<PayLine> lineas;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Desglose por concepto',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (lineas.isEmpty)
              Text('Sin actividad en el período.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ))
            else
              for (final l in lineas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${l.categoria.etiqueta} · ${Fmt.horas(l.horas)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(Fmt.moneda(l.importe),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icon,
  });

  final String titulo;
  final String valor;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(valor,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
        const SizedBox(height: 4),
        Text(titulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.titulo, this.valor, this.color);

  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(titulo)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TarjetaGraficoDias extends StatelessWidget {
  const _TarjetaGraficoDias({
    required this.sesiones,
    required this.desde,
    required this.hasta,
  });

  final List<SessionPayReport> sesiones;
  final DateTime desde;
  final DateTime hasta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dias = hasta.difference(desde).inDays;
    final horasPorDia = List<double>.filled(dias <= 0 ? 1 : dias, 0);
    for (final s in sesiones) {
      final idx = DateTime(s.sesion.inicio.year, s.sesion.inicio.month, s.sesion.inicio.day)
          .difference(desde)
          .inDays;
      if (idx >= 0 && idx < horasPorDia.length) {
        horasPorDia[idx] += s.totalHoras;
      }
    }
    final maxHoras = horasPorDia.fold<double>(0, (a, h) => h > a ? h : a);
    final sinActividad = maxHoras <= 0;
    final barraAncha = horasPorDia.length <= 10;

    // Eje Y legible: paso redondo (n.º entero de horas) y techo redondeado al
    // múltiplo del paso, con líneas guía horizontales para leer cada valor.
    final paso = _pasoHoras(maxHoras);
    final techoY = _techoHoras(maxHoras, paso);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Horas por día',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: sinActividad
                  ? Center(
                      child: Text('Sin actividad en el período.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              )),
                    )
                  : BarChart(
                      BarChartData(
                        maxY: techoY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: paso,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: scheme.outlineVariant.withValues(alpha: 0.45),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            // Título del eje: aclara la unidad de las barras.
                            axisNameWidget: Text('Horas',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600)),
                            axisNameSize: 22,
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: paso,
                              getTitlesWidget: (value, meta) {
                                // Redondear al múltiplo de paso más cercano:
                                // fl_chart pasa valores con leve error de
                                // punto flotante (p. ej. 4.0000001) que rompería
                                // un filtro `value % paso == 0` y ocultaría todo.
                                final v = (value / paso).roundToDouble() * paso;
                                final esEntero = (v % 1).abs() < 0.001;
                                final texto = esEntero
                                    ? v.toInt().toString()
                                    : v.toStringAsFixed(1);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(texto,
                                      style: Theme.of(context).textTheme.bodySmall),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (horasPorDia.length > 15 && i % 5 != 0) {
                                  return const SizedBox.shrink();
                                }
                                final dia = desde.add(Duration(days: i));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('${dia.day}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < horasPorDia.length; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                toY: horasPorDia[i],
                                color: scheme.primary,
                                width: barraAncha ? 14 : 4,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ]),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Paso del eje Y en horas enteras (redondo) según el máximo de horas del
  /// período, para que las marcas sean fáciles de leer.
  double _pasoHoras(double maxH) {
    if (maxH <= 2) return 0.5;
    if (maxH <= 4) return 1;
    if (maxH <= 8) return 2;
    if (maxH <= 16) return 4;
    return 8;
  }

  /// Redondea el máximo hacia arriba al siguiente múltiplo de [paso].
  double _techoHoras(double v, double paso) =>
      v <= 0 ? paso : (v / paso).ceilToDouble() * paso;
}

class _TarjetaGraficoCategorias extends StatelessWidget {
  const _TarjetaGraficoCategorias({required this.lineas});

  final List<PayLine> lineas;

  static const _colores = [
    Colors.blue,
    Colors.teal,
    Colors.deepOrange,
    Colors.purple,
    Colors.indigo,
    Colors.brown,
    Colors.pink,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalHoras = lineas.fold<double>(0, (a, l) => a + l.horas);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Proporción por tipo de jornada',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (lineas.isEmpty || totalHoras <= 0)
              Text('Sin actividad en el período.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ))
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: [
                          for (var i = 0; i < lineas.length; i++)
                            PieChartSectionData(
                              value: lineas[i].horas,
                              color: _colores[i % _colores.length],
                              showTitle: false,
                              radius: 30,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < lineas.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _colores[i % _colores.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${lineas[i].categoria.etiqueta} · '
                                    '${(lineas[i].horas / totalHoras * 100).toStringAsFixed(0)}%',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NotaLegal extends StatelessWidget {
  const _NotaLegal();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      'Cálculo estimado según el Código de Trabajo de RD (Ley 16-92). '
      'Los porcentajes son editables en Ajustes y el resultado es una guía, '
      'no constituye asesoría legal.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
    );
  }
}