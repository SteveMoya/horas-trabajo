import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/domain/salary/salary_engine.dart';
import 'package:horas_trabajo/state/app_state.dart';

/// Hoja inferior para editar una sesión: nota, marcas de feriado/descanso y
/// desglose del pago según el motor RD.
class SessionDetailSheet extends StatefulWidget {
  const SessionDetailSheet({super.key, required this.app, required this.sesion});

  final AppState app;
  final WorkSession sesion;

  @override
  State<SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<SessionDetailSheet> {
  late final TextEditingController _nota;

  @override
  void initState() {
    super.initState();
    _nota = TextEditingController(text: widget.sesion.nota);
  }

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  bool get _esFeriado => widget.sesion.esFeriado;
  bool get _esDescanso => widget.sesion.esDescansoSemanal;

  Future<void> _guardarCambios() async {
    final s = widget.sesion.copyWith(
      nota: _nota.text.trim(),
      esFeriado: _esFeriado,
      esDescansoSemanal: _esDescanso,
    );
    await widget.app.actualizarSesion(s);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sesion;
    final scheme = Theme.of(context).colorScheme;
    final report = widget.app.motor.calcularSesionUnica(s);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Fmt.fechaLarga(s.inicio),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 4),
          Text(
            '${Fmt.horaCorta(s.inicio)} – '
            '${s.fin == null ? 'en curso' : Fmt.horaCorta(s.fin!)} · '
            '${Fmt.duracionExtendida(s.duracion)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (s.latitud != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '📍 ${s.latitud!.toStringAsFixed(5)}, ${s.longitud!.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 16),

          TextField(
            controller: _nota,
            onChanged: (_) => _guardarCambios(),
            decoration: const InputDecoration(
              labelText: 'Nota',
              hintText: 'Descripción opcional del turno',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: FilterChip(
                  selected: _esFeriado,
                  onSelected: (_) {
                    _toggleFeriado();
                  },
                  label: const Text('Día feriado'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  selected: _esDescanso,
                  onSelected: (_) {
                    _toggleDescanso();
                  },
                  label: const Text('Descanso semanal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Desglose del pago',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (report.lineas.isEmpty)
            Text('Sin cálculo (jornada vacía o curso).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ))
          else ...[
            for (final l in report.lineas) _LineaPago(linea: l),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(Fmt.moneda(report.importeTotal),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _toggleFeriado() async {
    await widget.app.actualizarSesion(
      widget.sesion.copyWith(esFeriado: !_esFeriado),
    );
  }

  void _toggleDescanso() async {
    await widget.app.actualizarSesion(
      widget.sesion.copyWith(esDescansoSemanal: !_esDescanso),
    );
  }
}

class _LineaPago extends StatelessWidget {
  const _LineaPago({required this.linea});

  final PayLine linea;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${linea.categoria.etiqueta} · ${Fmt.horas(linea.horas)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '×${linea.factor.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 12),
          Text(
            Fmt.moneda(linea.importe),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}