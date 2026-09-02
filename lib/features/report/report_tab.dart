import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/domain/salary/salary_engine.dart';
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hoy = DateTime.now();
    final (desde, hasta) = _rango(hoy);
    final report = app.motor.calcularRango(app.sesiones, desde: desde, hasta: hasta);

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte')),
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
          _TarjetaTotales(report: report),
          const SizedBox(height: 16),
          _TarjetaDesglose(lineas: report.lineasConsolidadas),
          const SizedBox(height: 16),
          const _NotaLegal(),
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