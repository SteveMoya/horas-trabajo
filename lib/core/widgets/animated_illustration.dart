import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/illustrations/app_illustrations.dart';
import 'package:horas_trabajo/core/theme/app_motion.dart';
import 'package:horas_trabajo/core/utils/accessibility.dart';
import 'package:horas_trabajo/core/widgets/app_illustration.dart';

/// [AppIllustration] con animación de entrada (fade + leve escala y
/// desplazamiento) y, opcionalmente, una flotación ambiental continua y
/// muy sutil — pensada para ilustraciones protagonistas como la de
/// bienvenida del onboarding o los estados vacíos/de error.
///
/// Respeta "Quitar animaciones" del sistema (ver [reducirMovimiento]): sin
/// esa preferencia activa aparece con la transición completa; con ella,
/// se muestra directamente en su posición final y sin flotación.
class AnimatedIllustration extends StatefulWidget {
  const AnimatedIllustration(
    this.asset, {
    super.key,
    this.size,
    this.semanticLabel,
    this.ambient = false,
    this.delay = Duration.zero,
  });

  final AppIllustrationAsset asset;
  final double? size;
  final String? semanticLabel;

  /// Flotación vertical continua y muy sutil, además de la entrada.
  final bool ambient;

  /// Retraso antes de iniciar la entrada, para escalonar varias
  /// ilustraciones o textos dentro de una misma pantalla.
  final Duration delay;

  @override
  State<AnimatedIllustration> createState() => _AnimatedIllustrationState();
}

class _AnimatedIllustrationState extends State<AnimatedIllustration>
    with TickerProviderStateMixin {
  static const _amplitudAmbiente = 5.0;

  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: AppMotion.entrance,
  );
  late final AnimationController _ambiente = AnimationController(
    vsync: this,
    duration: AppMotion.ambient,
  );
  late final _curva = CurvedAnimation(parent: _entrada, curve: AppMotion.emphasized);

  bool _configurado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configurado) return;
    _configurado = true;
    if (reducirMovimiento(context)) {
      _entrada.value = 1;
      _ambiente.value = 0.5;
      return;
    }
    Future.delayed(widget.delay, () {
      if (mounted) _entrada.forward();
    });
    if (widget.ambient) _ambiente.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrada.dispose();
    _ambiente.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_curva, _ambiente]),
      builder: (context, child) {
        final flotacion =
            widget.ambient ? (_ambiente.value - 0.5) * 2 * _amplitudAmbiente : 0.0;
        return Opacity(
          opacity: _curva.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _curva.value) * 16 + flotacion),
            child: Transform.scale(
              scale: 0.94 + _curva.value * 0.06,
              child: child,
            ),
          ),
        );
      },
      child: AppIllustration(
        widget.asset,
        size: widget.size,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}
