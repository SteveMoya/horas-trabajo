import 'dart:async';

import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Timer? _tick;
  DateTime _ahora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _ahora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  DateTime get _inicioHoy => DateTime(_ahora.year, _ahora.month, _ahora.day);

  bool _enHoy(WorkSession s) =>
      !s.inicio.isBefore(_inicioHoy) &&
      s.inicio.isBefore(_inicioHoy.add(const Duration(days: 1)));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final activa = app.activa;

    final hoyMinutos = app.sesiones.fold<Duration>(
      Duration.zero,
      (acc, s) => acc + (s.enProgreso ? _ahora.difference(s.inicio) : s.duracion),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcar Horas'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: Chip(
                avatar: Icon(Icons.calendar_today, size: 16, color: scheme.primary),
                label: Text(Fmt.fechaCorta(_ahora)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!app.perfilCompleto) const _AvisoPerfil(),
            const SizedBox(height: 16),
            _TarjetaReloj(
              activa: activa,
              hora: _ahora,
              duraActiva: activa == null
                  ? Duration.zero
                  : _ahora.difference(activa.inicio),
              procesando: app.procesando,
              onAccion: () => _accionMarcar(context, app),
            ),
            const SizedBox(height: 16),
            _TarjetaResumenDia(
              horas: hoyMinutos,
              totalSesiones: app.sesiones.where(_enHoy).length,
              salarioHora:
                  app.perfil.salarioMensual > 0 ? app.motor.valorHoraOrdinaria : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accionMarcar(BuildContext context, AppState app) async {
    final snack = ScaffoldMessenger.of(context);
    if (app.activa != null) {
      await app.registrarSalida();
      snack.showSnackBar(const SnackBar(content: Text('Salida registrada ✅')));
    } else {
      await app.registrarEntrada();
      snack.showSnackBar(const SnackBar(content: Text('Entrada registrada ⏱️')));
    }
  }
}

class _TarjetaReloj extends StatelessWidget {
  const _TarjetaReloj({
    required this.activa,
    required this.hora,
    required this.duraActiva,
    required this.procesando,
    required this.onAccion,
  });

  final WorkSession? activa;
  final DateTime hora;
  final Duration duraActiva;
  final bool procesando;
  final VoidCallback onAccion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enCurso = activa != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              Fmt.horaCorta(hora),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              enCurso ? 'Sesión en curso' : 'Fuera de la jornada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: enCurso ? scheme.primary : scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              enCurso ? Fmt.duracionExtendida(duraActiva) : 'Pulsa para marcar tu entrada',
              style: enCurso
                  ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )
                  : Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: procesando ? null : onAccion,
                style: FilledButton.styleFrom(
                  backgroundColor: enCurso ? scheme.tertiaryContainer : scheme.primary,
                  foregroundColor: enCurso ? scheme.onTertiaryContainer : scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(enCurso ? Icons.stop_circle_outlined : Icons.play_arrow),
                label: Text(enCurso ? 'Registrar salida' : 'Registrar entrada',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaResumenDia extends StatelessWidget {
  const _TarjetaResumenDia({
    required this.horas,
    required this.totalSesiones,
    required this.salarioHora,
  });

  final Duration horas;
  final int totalSesiones;
  final double? salarioHora;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen de hoy',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                _Kpi(
                  icon: Icons.schedule,
                  valor: Fmt.duracionExtendida(horas),
                  etiqueta: 'Horas hoy',
                  color: scheme.primary,
                ),
                _Kpi(
                  icon: Icons.touch_app,
                  valor: '$totalSesiones',
                  etiqueta: 'Registros',
                  color: scheme.secondary,
                ),
                if (salarioHora != null)
                  _Kpi(
                    icon: Icons.payments,
                    valor: Fmt.moneda(salarioHora!),
                    etiqueta: 'Hora ordinaria',
                    color: scheme.tertiary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  final IconData icon;
  final String valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(valor,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  )),
          const SizedBox(height: 2),
          Text(etiqueta,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

class _AvisoPerfil extends StatelessWidget {
  const _AvisoPerfil();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Completa tu perfil (salario mensual) en Ajustes para ver el cálculo de horas.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}