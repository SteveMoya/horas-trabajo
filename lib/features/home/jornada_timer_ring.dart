import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';

/// Fase en la que se encuentra la jornada en vivo, que define el color y la
/// etiqueta del anillo circular de progreso.
enum JornadaFase {
  /// Aún no se completó la jornada ordinaria (anillo azul de marca).
  ordinaria,

  /// Ya se superó la jornada diaria: se están acumulando horas extra
  /// (recargo +35%), el anillo pasa a naranja y sigue girando.
  extra,

  /// La hora actual cae dentro de la franja nocturna configurada
  /// (9pm–7am por defecto, recargo +15%), el anillo se tiñe de violeta.
  nocturna;
}

/// Anillo circular que muestra en vivo cuánto de la jornada ordinaria se ha
/// completado y qué fase aplica mientras la sesión sigue activa.
///
/// Comportamiento:
/// - Llena el círculo (0°→360°) a medida que transcurre cada segundo hasta
///   completar la jornada diaria ([jornada]).
/// - Al superar la jornada, cambia de color (naranja) y continúa girando
///   para reflejar las horas extra acumuladas.
/// - Si la hora actual está en la franja nocturna, el arco se tiñe de violeta.
///
/// Las transiciones de color y de arco están animadas por
/// [TweenAnimationBuilder], por lo que el avance y el cambio de fase se ven
/// suaves en lugar de saltos bruscos.
class JornadaTimerRing extends StatelessWidget {
  const JornadaTimerRing({
    super.key,
    required this.elapsed,
    required this.jornada,
    required this.esNocturno,
    this.size = 240,
  });

  /// Tiempo transcurrido en la sesión activa.
  final Duration elapsed;

  /// Duración de la jornada ordinaria (p. ej. 8 h). Es el 100% del círculo.
  final Duration jornada;

  /// `true` si la hora actual cae dentro de la franja nocturna.
  final bool esNocturno;

  /// Diámetro exterior del anillo en píxeles lógicos.
  final double size;

  JornadaFase get _fase {
    if (esNocturno) return JornadaFase.nocturna;
    if (elapsed >= jornada) return JornadaFase.extra;
    return JornadaFase.ordinaria;
  }

  /// Color principal de la fase actual.
  Color _colorFase(Brightness brightness) => switch (_fase) {
        JornadaFase.ordinaria => const Color(0xFF1565C0),
        JornadaFase.extra => const Color(0xFFF57C00),
        JornadaFase.nocturna => const Color(0xFF7C3AED),
      };

  String get _etiqueta => switch (_fase) {
        JornadaFase.ordinaria => 'Jornada ordinaria',
        JornadaFase.extra => 'Horas extra · +35%',
        JornadaFase.nocturna => 'Tanda nocturna · +15%',
      };

  String get _subtituloFase {
    final restante = jornada - elapsed;
    switch (_fase) {
      case JornadaFase.ordinaria:
        return restante > Duration.zero
            ? 'Te faltan ${_duracionCorta(restante)} de la jornada'
            : 'Jornada completada 🎉';
      case JornadaFase.extra:
        final extra = elapsed - jornada;
        return 'Has ganado ${_duracionCorta(extra)} en extra';
      case JornadaFase.nocturna:
        return 'Franja nocturna activa (9pm–7am)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fase = _fase;
    final color = _colorFase(theme.brightness);

    return Semantics(
      label: '$_etiqueta, ${Fmt.duracionExtendida(elapsed)} trabajadas',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progreso),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, progreso, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pista trasera (siempre completa, muy tenue).
                    Positioned.fill(
                      child: _Track(esNocturno: esNocturno, esNocturnoFase: fase == JornadaFase.nocturna),
                    ),
                    // Arco principal con glow, coloreado según la fase.
                    Positioned.fill(
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(begin: color, end: color),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, c, _) =>
                            _Arc(sweep: progreso, color: c ?? color),
                      ),
                    ),
                    // Punto luminoso en la punta del arco.
                    Positioned.fill(
                      child: _TipDot(color: color, sweep: progreso),
                    ),
                    // Centro: número y etiquetas.
                    _Centro(
                      elapsed: elapsed,
                      fase: fase,
                      color: color,
                      etiqueta: _etiqueta,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _subtituloFase,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: phaseContrast(scheme, color),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Progreso del arco como fracción de la jornada. Puede superar 1.0
  /// cuando ya hay horas extra (el círculo sigue girando más de una vuelta).
  double get _progreso {
    final totalSeg = elapsed.inSeconds >= 0 ? elapsed.inSeconds : 0;
    final jornadaSeg = jornada.inSeconds > 0 ? jornada.inSeconds : 1;
    return totalSeg / jornadaSeg;
  }

  /// Formatea una duración corta como "8h 30m" (reutiliza el estilo de la app).
  static String _duracionCorta(Duration d) => Fmt.duracionExtendida(d);
}

/// Devuelve un color de texto legible sobre [faseColor].
Color phaseContrast(ColorScheme scheme, Color faseColor) {
  // Si la fase usa un color de marca brillante y estamos en modo oscuro se
  // tiende a usar el propio color; por claridad se prefiere onSurface salvo
  // en el subtítulo por defecto.
  return scheme.onSurface.withValues(alpha: 0.78);
}

class _Track extends StatelessWidget {
  const _Track({required this.esNocturno, required this.esNocturnoFase});

  final bool esNocturno;
  final bool esNocturnoFase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _TrackPainter(
        color: isDark
            ? (esNocturnoFase
                ? const Color(0xFF3A2B63)
                : scheme.surfaceContainerHighest)
            : (esNocturnoFase
                ? const Color(0xFFE8DEF8)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.7)),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(_TrackPainter old) => old.color != color;
}

class _Arc extends StatelessWidget {
  const _Arc({required this.sweep, required this.color});
  final double sweep;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ArcPainter(sweep: sweep, color: color));
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.sweep, required this.color});
  final double sweep;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepRad = sweep * 2 * math.pi;
    if (sweepRad <= 0) return;

    // Resplandor suave detrás del arco.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = color.withValues(alpha: 0.45);

    // Arco principal. El SweepGradient exige startAngle < endAngle, por lo que
    // solo se construye cuando hay progreso real (evita el assert en el frame
    // inicial de la animación, cuando sweep == 0).
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.55),
          color,
        ],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepRad,
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweepRad, false, glow);
    canvas.drawArc(rect, -math.pi / 2, sweepRad, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.sweep != sweep || old.color != color;
}

class _TipDot extends StatelessWidget {
  const _TipDot({required this.color, required this.sweep});
  final Color color;
  final double sweep;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TipDotPainter(color: color, sweep: sweep));
  }
}

class _TipDotPainter extends CustomPainter {
  const _TipDotPainter({required this.color, required this.sweep});
  final Color color;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final angle = -math.pi / 2 + sweep * 2 * math.pi;
    final pos = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final core = Paint()..color = color;
    final halo = Paint()..color = color.withValues(alpha: 0.25);
    canvas.drawCircle(pos, 8, halo);
    canvas.drawCircle(pos, 4.5, core);
  }

  @override
  bool shouldRepaint(_TipDotPainter old) =>
      old.sweep != sweep || old.color != color;
}

class _Centro extends StatelessWidget {
  const _Centro({
    required this.elapsed,
    required this.fase,
    required this.color,
    required this.etiqueta,
  });

  final Duration elapsed;
  final JornadaFase fase;
  final Color color;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60);
    final s = elapsed.inSeconds.remainder(60);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          switch (fase) {
            JornadaFase.ordinaria => Icons.check_circle_outline,
            JornadaFase.extra => Icons.trending_up,
            JornadaFase.nocturna => Icons.nightlight_round,
          },
          color: color,
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}