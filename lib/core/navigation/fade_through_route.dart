import 'package:flutter/material.dart';

/// Transición "fade through" (Material Motion) para navegar a una pantalla
/// completa nueva — más suave y consistente que el slide por defecto de
/// [MaterialPageRoute] para este tipo de navegación (Ajustes → sub-pantalla).
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final entrando = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            );
            final saliendo = CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(saliendo),
              child: FadeTransition(
                opacity: entrando,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1.0).animate(entrando),
                  child: child,
                ),
              ),
            );
          },
        );
}
