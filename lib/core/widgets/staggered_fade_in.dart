import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/accessibility.dart';

/// Envuelve [child] para que aparezca con un fade + leve desplazamiento
/// hacia arriba cuando la pantalla se construye por primera vez. El
/// "escalonado" entre elementos se logra dando a cada índice una duración
/// de animación progresivamente más larga (todos arrancan casi juntos, los
/// de índice mayor tardan un poco más en llegar), en vez de retrasar el
/// arranque con un Timer — evita manejar un AnimationController propio y
/// es una animación implícita estándar, más simple y predecible.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  /// En listas largas (historial), no tiene sentido que los últimos
  /// elementos tarden mucho más que los primeros en llegar.
  static const _maxIndiceEscalonado = 8;

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final indice = widget.index.clamp(0, _maxIndiceEscalonado);
    final duracion = reducirMovimiento(context)
        ? Duration.zero
        : Duration(milliseconds: 260 + 40 * indice);
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: duracion,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: duracion,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
