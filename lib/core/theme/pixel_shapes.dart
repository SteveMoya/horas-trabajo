import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Radios de esquina estándar de la app — reemplazan los valores sueltos
/// (12/14/16/20/30) repartidos por las pantallas antes de este cambio.
class PixelRadii {
  static const double small = 12;
  static const double medium = 20;
  static const double large = 28;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Borde con esquinas continuas ("squircle", superelipse) en vez del arco
/// circular por defecto de Material — la seña visual más reconocible de
/// Material You / Pixel: esquinas grandes y suaves, no un simple arco.
///
/// Se calcula por muestreo paramétrico de una superelipse
/// (`x = r·cos(t)^p`, `y = r·sin(t)^p` con `p = 2/n`, `n = 4`) restringido a
/// cada esquina — barato (solo corre en layout/rebuild, nunca por frame) y
/// sin riesgo de auto-intersección.
class SquircleBorder extends OutlinedBorder {
  const SquircleBorder({this.radius = PixelRadii.medium, super.side});

  final double radius;

  static const int _puntosPorEsquina = 10;
  static const double _exponente = 0.5; // 2/n con n = 4

  @override
  SquircleBorder copyWith({BorderSide? side, double? radius}) =>
      SquircleBorder(radius: radius ?? this.radius, side: side ?? this.side);

  @override
  ShapeBorder scale(double t) =>
      SquircleBorder(radius: radius * t, side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SquircleBorder) {
      return SquircleBorder(
        radius: _lerp(a.radius, radius, t),
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SquircleBorder) {
      return SquircleBorder(
        radius: _lerp(radius, b.radius, t),
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _trazar(rect, radius);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _trazar(rect.deflate(side.width), radius - side.width);

  Path _trazar(Rect rect, double radioDeseado) {
    final path = Path();
    final radio = radioDeseado.clamp(0.0, rect.shortestSide / 2);
    if (radio <= 0) return path..addRect(rect);

    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;

    double pot(double x) => math.pow(x, _exponente).toDouble();

    path.moveTo(l + radio, t);
    path.lineTo(r - radio, t);

    // Esquina superior derecha: centro (r-radio, t+radio).
    final ctr1 = Offset(r - radio, t + radio);
    for (var i = 1; i <= _puntosPorEsquina; i++) {
      final ang = (i / _puntosPorEsquina) * (math.pi / 2);
      path.lineTo(
        ctr1.dx + radio * pot(math.sin(ang)),
        ctr1.dy - radio * pot(math.cos(ang)),
      );
    }

    path.lineTo(r, b - radio);

    // Esquina inferior derecha: centro (r-radio, b-radio).
    final ctr2 = Offset(r - radio, b - radio);
    for (var i = 1; i <= _puntosPorEsquina; i++) {
      final ang = (i / _puntosPorEsquina) * (math.pi / 2);
      path.lineTo(
        ctr2.dx + radio * pot(math.cos(ang)),
        ctr2.dy + radio * pot(math.sin(ang)),
      );
    }

    path.lineTo(l + radio, b);

    // Esquina inferior izquierda: centro (l+radio, b-radio).
    final ctr3 = Offset(l + radio, b - radio);
    for (var i = 1; i <= _puntosPorEsquina; i++) {
      final ang = (i / _puntosPorEsquina) * (math.pi / 2);
      path.lineTo(
        ctr3.dx - radio * pot(math.sin(ang)),
        ctr3.dy + radio * pot(math.cos(ang)),
      );
    }

    path.lineTo(l, t + radio);

    // Esquina superior izquierda: centro (l+radio, t+radio).
    final ctr4 = Offset(l + radio, t + radio);
    for (var i = 1; i <= _puntosPorEsquina; i++) {
      final ang = (i / _puntosPorEsquina) * (math.pi / 2);
      path.lineTo(
        ctr4.dx - radio * pot(math.cos(ang)),
        ctr4.dy - radio * pot(math.sin(ang)),
      );
    }

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SquircleBorder && other.radius == radius && other.side == side;

  @override
  int get hashCode => Object.hash(radius, side);
}
