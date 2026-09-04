import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/illustrations/app_illustrations.dart';
import 'package:horas_trabajo/core/theme/app_spacing.dart';
import 'package:horas_trabajo/core/widgets/animated_illustration.dart';

/// Base compartida de [EmptyState], [ErrorState] y [SuccessState]: una
/// ilustración animada, título, mensaje opcional y acción opcional. En
/// [compact] (para usarse dentro de una Card, junto a un gráfico u otro
/// contenido) reduce tamaños y evita el `Center` a pantalla completa.
class _IllustratedState extends StatelessWidget {
  const _IllustratedState({
    required this.illustration,
    required this.titulo,
    this.mensaje,
    this.accion,
    this.compact = false,
    this.ambient = false,
  });

  final AppIllustrationAsset illustration;
  final String titulo;
  final String? mensaje;
  final Widget? accion;
  final bool compact;
  final bool ambient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final contenido = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedIllustration(
          illustration,
          size: compact ? 88 : 168,
          semanticLabel: titulo,
          ambient: ambient,
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: (compact
                  ? Theme.of(context).textTheme.titleSmall
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (mensaje != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            mensaje!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
        if (accion != null) ...[
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
          accion!,
        ],
      ],
    );
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.lg : AppSpacing.xxxl,
          vertical: compact ? AppSpacing.sm : 0,
        ),
        child: contenido,
      ),
    );
  }
}

/// Estado vacío reutilizable: "todavía no hay nada acá". Úsalo cuando una
/// lista o sección no tiene datos que mostrar, nunca solo para llenar
/// espacio — el mensaje debe orientar hacia la acción que llena ese vacío.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.titulo,
    this.mensaje,
    this.illustration = AppIllustrationAsset.empty,
    this.compact = false,
    this.accion,
  });

  final String titulo;
  final String? mensaje;
  final AppIllustrationAsset illustration;
  final bool compact;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => _IllustratedState(
        illustration: illustration,
        titulo: titulo,
        mensaje: mensaje,
        accion: accion,
        compact: compact,
      );
}

/// Estado de error reutilizable, con acción opcional de reintentar. No
/// reemplaza los `SnackBar` de errores puntuales de una acción (marcar
/// entrada, exportar, etc.) — es para cuando una sección completa no pudo
/// cargar y necesita su propio espacio en pantalla.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.titulo = 'Algo salió mal',
    this.mensaje,
    this.illustration = AppIllustrationAsset.error,
    this.onRetry,
    this.compact = false,
  });

  final String titulo;
  final String? mensaje;
  final AppIllustrationAsset illustration;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => _IllustratedState(
        illustration: illustration,
        titulo: titulo,
        mensaje: mensaje,
        compact: compact,
        accion: onRetry == null
            ? null
            : FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
      );
}

/// Estado de éxito reutilizable, para el cierre de un flujo completo (por
/// ejemplo, el paso final del onboarding) — no para confirmaciones breves
/// de una acción puntual, que siguen usando `SnackBar`.
class SuccessState extends StatelessWidget {
  const SuccessState({
    super.key,
    required this.titulo,
    this.mensaje,
    this.illustration = AppIllustrationAsset.success,
    this.accion,
    this.compact = false,
  });

  final String titulo;
  final String? mensaje;
  final AppIllustrationAsset illustration;
  final Widget? accion;
  final bool compact;

  @override
  Widget build(BuildContext context) => _IllustratedState(
        illustration: illustration,
        titulo: titulo,
        mensaje: mensaje,
        accion: accion,
        compact: compact,
        ambient: true,
      );
}
