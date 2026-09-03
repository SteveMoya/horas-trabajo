import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/data/models/ausencia.dart';
import 'package:horas_trabajo/data/repositories/ausencias_repository.dart';
import 'package:horas_trabajo/domain/calendar/feriados_rd.dart';

/// Calendario de feriados de RD (Ley 139-97) y registro manual de
/// vacaciones/permisos/licencias.
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final _repo = AusenciasRepository();
  late int _anio = DateTime.now().year;
  List<Ausencia> _ausencias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ausencias = await _repo.obtenerTodas();
    if (!mounted) return;
    setState(() {
      _ausencias = ausencias;
      _cargando = false;
    });
  }

  Future<void> _agregarAusencia() async {
    final nueva = await showDialog<Ausencia>(
      context: context,
      builder: (_) => const _DialogoAusencia(),
    );
    if (nueva == null) return;
    await _repo.insertar(nueva);
    await _cargar();
  }

  Future<void> _eliminarAusencia(int id) async {
    await _repo.eliminar(id);
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final feriados = FeriadosRD.delAnio(_anio);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarAusencia,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Feriados',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: hoy.year, label: Text('${hoy.year}')),
                        ButtonSegment(
                            value: hoy.year + 1, label: Text('${hoy.year + 1}')),
                      ],
                      selected: {_anio},
                      onSelectionChanged: (s) => setState(() => _anio = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      for (final f in feriados)
                        ListTile(
                          leading: Icon(
                            f.fecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day))
                                ? Icons.event_available_outlined
                                : Icons.event_outlined,
                          ),
                          title: Text(f.nombre),
                          trailing: Text(Fmt.fechaCorta(f.fecha)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Vacaciones y permisos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_ausencias.isEmpty)
                  Text(
                    'Sin vacaciones ni permisos registrados.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (final a in _ausencias)
                          ListTile(
                            leading: const Icon(Icons.beach_access_outlined),
                            title: Text(a.tipo.etiqueta),
                            subtitle: Text(
                              '${Fmt.fechaCorta(a.fechaInicio)} - ${Fmt.fechaCorta(a.fechaFin)}'
                              '${a.nota.isNotEmpty ? '\n${a.nota}' : ''}',
                            ),
                            isThreeLine: a.nota.isNotEmpty,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Eliminar',
                              onPressed: () => _eliminarAusencia(a.id),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DialogoAusencia extends StatefulWidget {
  const _DialogoAusencia();

  @override
  State<_DialogoAusencia> createState() => _DialogoAusenciaState();
}

class _DialogoAusenciaState extends State<_DialogoAusencia> {
  DateTime _inicio = DateTime.now();
  DateTime _fin = DateTime.now();
  TipoAusencia _tipo = TipoAusencia.vacacion;
  final _nota = TextEditingController();

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final actual = esInicio ? _inicio : _fin;
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(actual.year - 1),
      lastDate: DateTime(actual.year + 2),
    );
    if (elegida == null) return;
    setState(() {
      if (esInicio) {
        _inicio = elegida;
        if (_fin.isBefore(_inicio)) _fin = _inicio;
      } else {
        _fin = elegida;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva ausencia'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final t in TipoAusencia.values)
                  ChoiceChip(
                    label: Text(t.etiqueta),
                    selected: _tipo == t,
                    onSelected: (_) => setState(() => _tipo = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Desde'),
              subtitle: Text(Fmt.fechaCorta(_inicio)),
              onTap: () => _elegirFecha(esInicio: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Hasta'),
              subtitle: Text(Fmt.fechaCorta(_fin)),
              onTap: () => _elegirFecha(esInicio: false),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nota,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            Ausencia(
              id: 0,
              fechaInicio: _inicio,
              fechaFin: _fin,
              tipo: _tipo,
              nota: _nota.text.trim(),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
