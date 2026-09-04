import 'package:flutter/animation.dart';

/// Duraciones y curvas estándar de animación — mismos valores que ya
/// usaban [MorphingBlob]/[StaggeredFadeIn]/[AnimatedTapScale], nombrados
/// para que el próximo componente animado los reuse en vez de inventar un
/// número nuevo.
class AppMotion {
  const AppMotion._();

  /// Microinteracciones (check de selección, feedback al tocar).
  static const fast = Duration(milliseconds: 150);

  /// Transiciones de UI puntuales (tarjeta seleccionada, indicador).
  static const base = Duration(milliseconds: 250);

  /// Navegación entre pantallas o páginas de un flujo.
  static const page = Duration(milliseconds: 380);

  /// Entrada de una ilustración protagonista.
  static const entrance = Duration(milliseconds: 480);

  /// Medio ciclo de una flotación ambiental en loop.
  static const ambient = Duration(seconds: 4);

  static const standard = Curves.easeOut;
  static const emphasized = Curves.easeOutCubic;
}
