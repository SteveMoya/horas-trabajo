import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/accessibility.dart';

/// Envoltorio que aplica un pequeño "squish" (escala) al presionar, para dar
/// feedback táctil inmediato en botones principales (además del ripple que
/// ya traen los widgets de Material).
class AnimatedTapScale extends StatefulWidget {
  const AnimatedTapScale({super.key, required this.child, this.scale = 0.96});

  final Widget child;
  final double scale;

  @override
  State<AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<AnimatedTapScale> {
  bool _presionado = false;

  void _set(bool valor) {
    if (_presionado != valor) setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _presionado && !reducirMovimiento(context) ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
