import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/data/models/workplace.dart';
import 'package:horas_trabajo/domain/calendar/feriados_rd.dart';
import 'package:horas_trabajo/core/widgets/animated_tap_scale.dart';
import 'package:horas_trabajo/core/widgets/staggered_fade_in.dart';
import 'package:horas_trabajo/domain/salary/salary_engine.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Timer? _tick;
  DateTime _ahora = DateTime.now();
  final stt.SpeechToText _voz = stt.SpeechToText();
  bool _escuchando = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _ahora = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    unawaited(_voz.stop());
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
      (acc, s) =>
          acc + (s.enProgreso ? _ahora.difference(s.inicio) : s.duracion),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Center(
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
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
            if (!app.perfilCompleto)
              const StaggeredFadeIn(index: 0, child: _AvisoPerfil()),
            const SizedBox(height: 16),
            StaggeredFadeIn(
              index: 1,
              child: _TarjetaMarcador(
                activa: activa,
                ahora: _ahora,
                duraActiva: activa == null
                    ? Duration.zero
                    : _ahora.difference(activa.inicio),
                procesando: app.procesando,
                onEntrada: () => _pulsarEntrada(app),
                onSalida: () => _pulsarSalida(app),
                escuchando: _escuchando,
                onVoz: () => _alternarEscucha(app),
              ),
            ),
            if (activa != null) ...[
              const SizedBox(height: 16),
              StaggeredFadeIn(
                index: 2,
                child: _TarjetaIngresoEnVivo(
                  reporte: app.perfil.salarioMensual > 0
                      ? app.motor.calcularSesionUnica(
                          activa.copyWith(fin: _ahora),
                        )
                      : null,
                ),
              ),
            ],
            const SizedBox(height: 16),
            StaggeredFadeIn(
              index: 3,
              child: _TarjetaTrabajo(
                app: app,
                activa: activa,
                onToggleMonitoreo: () => _alternarMonitor(app),
              ),
            ),
            const SizedBox(height: 16),
            StaggeredFadeIn(
              index: 4,
              child: _TarjetaResumenDia(
                horas: hoyMinutos,
                totalSesiones: app.sesiones.where(_enHoy).length,
                salarioHora: app.perfil.salarioMensual > 0
                    ? app.motor.valorHoraOrdinaria
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Flujo de marcado -----

  Future<void> _pulsarEntrada(AppState app) async {
    if (app.activa != null) return;
    final messenger = ScaffoldMessenger.of(context);

    // Modo sin GPS: no se pide permiso ni ubicación, se marca directo.
    final gps = app.usarUbicacion ? await app.pedirUbicacion() : null;

    // Primera vez: ofrecer guardar como lugar de trabajo.
    if (gps != null && app.workplace == null && mounted) {
      final guardar = await _confirmarLugarDeTrabajo(context, gps);
      if (guardar == true) {
        await app.guardarWorkplace(Workplace(
          id: DateTime.now().millisecondsSinceEpoch,
          latitud: gps[0],
          longitud: gps[1],
          nombre: 'Mi lugar de trabajo',
          creadoEn: DateTime.now(),
        ));
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Lugar de trabajo guardado ✅')),
          );
        }
      }
    }

    // Si hoy es feriado (Ley 139-97), ofrecer marcar la jornada como tal.
    var esFeriado = false;
    final feriado = FeriadosRD.feriadoEn(DateTime.now());
    if (feriado != null && mounted) {
      esFeriado = await _confirmarFeriado(context, feriado.nombre) ?? false;
    }

    await app.registrarEntrada(ubicacion: gps, esFeriado: esFeriado);
    if (mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Entrada registrada ⏱️')));
    }
  }

  Future<bool?> _confirmarFeriado(BuildContext context, String nombre) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration_outlined, size: 34),
        title: const Text('¿Hoy es feriado?'),
        content: Text(
          'Hoy es $nombre. ¿Marcar esta jornada como feriado (paga doble)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, marcar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pulsarSalida(AppState app) async {
    await app.registrarSalida();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Salida registrada ✅')));
    }
  }

  // ----- Marcado por voz -----

  Future<void> _alternarEscucha(AppState app) async {
    final messenger = ScaffoldMessenger.of(context);
    if (_escuchando) {
      await _voz.stop();
      if (mounted) setState(() => _escuchando = false);
      return;
    }

    final disponible = await _voz.initialize();
    if (!disponible) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Reconocimiento de voz no disponible')),
      );
      return;
    }

    setState(() => _escuchando = true);
    // Sin localeId explícito: usa el idioma configurado en el dispositivo
    // (evita fallar si "es_DO" no está entre los paquetes de voz instalados).
    await _voz.listen(
      onResult: (resultado) {
        if (!resultado.finalResult) return;
        _procesarComandoVoz(app, resultado.recognizedWords);
      },
    );
  }

  void _procesarComandoVoz(AppState app, String texto) {
    if (mounted) setState(() => _escuchando = false);
    final normalizado = _sinAcentos(texto.toLowerCase());
    if (normalizado.contains('salida')) {
      _pulsarSalida(app);
    } else if (normalizado.contains('entrada')) {
      _pulsarEntrada(app);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            texto.isEmpty
                ? 'No te escuché. Decí "marcar entrada" o "marcar salida"'
                : 'No entendí "$texto". Decí "marcar entrada" o "marcar salida"',
          ),
        ),
      );
    }
  }

  String _sinAcentos(String s) => s
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  Future<void> _alternarMonitor(AppState app) async {
    final messenger = ScaffoldMessenger.of(context);
    if (app.monitoreando) {
      await app.desactivarMonitor();
      messenger.showSnackBar(const SnackBar(content: Text('Vigilancia desactivada')));
      return;
    }
    final MonitoreoResultado res;
    try {
      res = await app.activarMonitor();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo activar la vigilancia')),
        );
      }
      return;
    }
    if (!mounted) return;
    switch (res) {
      case MonitoreoResultado.activado:
        messenger.showSnackBar(
          const SnackBar(content: Text('Vigilando llegada y salida 🛰️')),
        );
        break;
      case MonitoreoResultado.sinLugarTrabajo:
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Primero guarda un lugar de trabajo para vigilar')),
        );
        break;
      case MonitoreoResultado.permisoDenegado:
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Permite el acceso a la ubicación en el popup del sistema')),
        );
        break;
      case MonitoreoResultado.permisoPermanente:
        messenger.showSnackBar(
          const SnackBar(
              content:
                  Text('Abre los ajustes y activa la ubicación ("Permitir todo el tiempo")')),
        );
        await Geolocator.openAppSettings();
        break;
      case MonitoreoResultado.gpsApagado:
        messenger.showSnackBar(
          const SnackBar(content: Text('Activa la ubicación (GPS) del teléfono')),
        );
        break;
      case MonitoreoResultado.notificacionesDenegadas:
        messenger.showSnackBar(
          const SnackBar(
              content:
                  Text('Activa las notificaciones de la app (ajustes > Notificaciones) para poder vigilar en segundo plano')),
        );
        break;
      case MonitoreoResultado.fallo:
        messenger.showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo iniciar la vigilancia. Asegúrate de permitir las notificaciones y vuelve a intentarlo')),
        );
        break;
    }
  }

  Future<bool?> _confirmarLugarDeTrabajo(
    BuildContext context,
    List<double> gps,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.work_outline, size: 34),
        title: const Text('¿Guardar lugar de trabajo?'),
        content: const Text(
          '¿Quieres guardar esta ubicación como tu lugar de trabajo '
          'para recibir avisos al llegar y al salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, gracias'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, guardar'),
          ),
        ],
      ),
    );
  }
}

class _TarjetaMarcador extends StatelessWidget {
  const _TarjetaMarcador({
    required this.activa,
    required this.ahora,
    required this.duraActiva,
    required this.procesando,
    required this.onEntrada,
    required this.onSalida,
    required this.escuchando,
    required this.onVoz,
  });

  final WorkSession? activa;
  final DateTime ahora;
  final Duration duraActiva;
  final bool procesando;
  final VoidCallback onEntrada;
  final VoidCallback onSalida;
  final bool escuchando;
  final VoidCallback onVoz;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enCurso = activa != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(
              Fmt.horaCorta(ahora),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              enCurso ? 'Sesión en curso' : 'Fuera de la jornada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: enCurso ? scheme.primary : scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: enCurso
                  ? Container(
                      key: const ValueKey('badge-duracion'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        Fmt.duracionExtendida(duraActiva),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    )
                  : const SizedBox(key: ValueKey('badge-vacio')),
            ),
            const SizedBox(height: 22),
            AnimatedTapScale(
              child: SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: enCurso
                      ? FilledButton.icon(
                          key: const ValueKey('boton-salida'),
                          onPressed: procesando ? null : onSalida,
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.errorContainer,
                            foregroundColor: scheme.onErrorContainer,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          icon: const Icon(Icons.logout, size: 26),
                          label: const Text('Marcar salida', style: TextStyle(fontSize: 20)),
                        )
                      : FilledButton.icon(
                          key: const ValueKey('boton-entrada'),
                          onPressed: procesando ? null : onEntrada,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          icon: const Icon(Icons.login, size: 26),
                          label: const Text('Marcar entrada', style: TextStyle(fontSize: 20)),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedTapScale(
              scale: 0.92,
              child: TextButton.icon(
                onPressed: procesando ? null : onVoz,
                icon: _IconoMicrofono(escuchando: escuchando, color: scheme.error),
                label: Text(escuchando ? 'Escuchando…' : 'Marcar por voz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícono de micrófono con un pulso continuo mientras [escuchando] es `true`,
/// para reforzar visualmente que el reconocimiento de voz sigue activo.
class _IconoMicrofono extends StatefulWidget {
  const _IconoMicrofono({required this.escuchando, required this.color});

  final bool escuchando;
  final Color color;

  @override
  State<_IconoMicrofono> createState() => _IconoMicrofonoState();
}

class _IconoMicrofonoState extends State<_IconoMicrofono>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.escuchando) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_IconoMicrofono oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.escuchando && !oldWidget.escuchando) {
      _controller.repeat(reverse: true);
    } else if (!widget.escuchando && oldWidget.escuchando) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.escuchando) {
      return const Icon(Icons.mic_none);
    }
    return ScaleTransition(
      scale: Tween(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Icon(Icons.mic, color: widget.color),
    );
  }
}

class _TarjetaIngresoEnVivo extends StatelessWidget {
  const _TarjetaIngresoEnVivo({required this.reporte});

  /// `null` cuando el perfil aún no tiene salario mensual configurado.
  final SessionPayReport? reporte;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reporte = this.reporte;
    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Ganado en esta jornada',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (reporte == null)
              Text(
                'Completa tu salario mensual en Ajustes para ver el ingreso en vivo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              )
            else ...[
              Text(
                Fmt.moneda(reporte.importeTotal),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
              ),
              if (reporte.lineas.isNotEmpty) ...[
                const Divider(height: 24),
                for (final l in reporte.lineas) _FilaIngreso(linea: l),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaIngreso extends StatelessWidget {
  const _FilaIngreso({required this.linea});

  final PayLine linea;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${linea.categoria.etiqueta} · ${Fmt.horas(linea.horas)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            Fmt.moneda(linea.importe),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaTrabajo extends StatelessWidget {
  const _TarjetaTrabajo({
    required this.app,
    required this.activa,
    required this.onToggleMonitoreo,
  });

  final AppState app;
  final WorkSession? activa;
  final VoidCallback onToggleMonitoreo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wp = app.workplace;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            SwitchListTile(
              value: app.monitoreando,
              onChanged: app.usarUbicacion ? (_) => onToggleMonitoreo() : null,
              title: const Text('Vigilar llegada y salida'),
              subtitle: Text(
                !app.usarUbicacion
                    ? 'Desactivada: modo sin GPS activo (Ajustes)'
                    : app.monitoreando
                        ? 'Avisos al llegar/salir del trabajo'
                        : 'Notificaciones de geocerca',
              ),
              secondary: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  app.monitoreando ? Icons.gps_fixed : Icons.gps_not_fixed,
                  key: ValueKey(app.monitoreando),
                  color: app.monitoreando ? scheme.primary : scheme.outline,
                ),
              ),
            ),
            if (wp != null)
              ListTile(
                leading: Icon(
                  app.dentro ? Icons.business : Icons.north_west,
                  color: app.dentro ? scheme.primary : scheme.tertiary,
                ),
                title: Text(wp.nombre),
                subtitle: Text(
                  app.monitoreando
                      ? (app.dentro
                          ? 'Estás dentro del área de trabajo'
                          : 'Fuera del área de trabajo')
                      : 'Radio ${wp.radioMetros.round()} m',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final quitar = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Lugar de trabajo'),
                      content: Text(
                        '📍 ${wp.latitud.toStringAsFixed(5)}, '
                        '${wp.longitud.toStringAsFixed(5)}\n'
                        'Radio: ${wp.radioMetros.round()} m',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cerrar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (quitar == true && context.mounted) {
                    await app.quitarWorkplace();
                  }
                },
              )
            else
              const ListTile(
                leading: Icon(Icons.add_location_alt_outlined),
                title: Text('Sin lugar de trabajo'),
                subtitle: Text(
                    'Al marcar tu primera entrada podrás guardar la ubicación'),
                onTap: null,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
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