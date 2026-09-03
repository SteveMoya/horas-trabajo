import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/accessibility.dart';

/// Preset de forma orgánica ("blob"): el radio varía por ángulo siguiendo
/// una onda senoidal — inspirado en las formas fluidas que Pixel usa en
/// At a Glance, el reloj de pantalla bloqueada y el widget del clima.
class PixelBlob {
  const PixelBlob({
    required this.amplitud,
    required this.frecuencia,
    required this.fase,
  });

  /// Proporción del radio base que varía (0..1).
  final double amplitud;

  /// Cantidad de "lóbulos" alrededor del círculo.
  final double frecuencia;

  final double fase;

  double radio(double base, double angulo) =>
      base * (1 + amplitud * math.sin(frecuencia * angulo + fase));
}

class PixelBlobs {
  static const suave = PixelBlob(amplitud: 0.09, frecuencia: 3, fase: 0);
  static const media = PixelBlob(amplitud: 0.13, frecuencia: 5, fase: math.pi / 3);
  static const marcada = PixelBlob(amplitud: 0.11, frecuencia: 4, fase: math.pi / 2);
}

/// Forma orgánica que morphea suavemente en loop entre dos [PixelBlob],
/// usada como fondo animado detrás de los íconos del onboarding. Respeta
/// la preferencia de accesibilidad "quitar animaciones": si está activa,
/// queda estática en el punto medio entre ambas formas.
class MorphingBlob extends StatefulWidget {
  const MorphingBlob({
    super.key,
    this.size = 120,
    this.color,
    this.child,
    this.blobA = PixelBlobs.suave,
    this.blobB = PixelBlobs.media,
    this.duracion = const Duration(seconds: 5),
  });

  final double size;
  final Color? color;
  final Widget? child;
  final PixelBlob blobA;
  final PixelBlob blobB;
  final Duration duracion;

  @override
  State<MorphingBlob> createState() => _MorphingBlobState();
}

class _MorphingBlobState extends State<MorphingBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duracion,
  );
  bool _configurado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configurado) return;
    _configurado = true;
    if (reducirMovimiento(context)) {
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primaryContainer;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, hijo) => CustomPaint(
        size: Size.square(widget.size),
        painter: _BlobPainter(
          t: _controller.value,
          blobA: widget.blobA,
          blobB: widget.blobB,
          color: color,
        ),
        child: Center(child: hijo),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter({
    required this.t,
    required this.blobA,
    required this.blobB,
    required this.color,
  });

  final double t;
  final PixelBlob blobA;
  final PixelBlob blobB;
  final Color color;

  static const _puntos = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final base = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i <= _puntos; i++) {
      final angulo = (i / _puntos) * 2 * math.pi;
      final ra = blobA.radio(base, angulo);
      final rb = blobB.radio(base, angulo);
      final r = ra + (rb - ra) * t;
      final punto = centro + Offset(math.cos(angulo), math.sin(angulo)) * r;
      if (i == 0) {
        path.moveTo(punto.dx, punto.dy);
      } else {
        path.lineTo(punto.dx, punto.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.color != color ||
      oldDelegate.blobA != blobA ||
      oldDelegate.blobB != blobB;
}
