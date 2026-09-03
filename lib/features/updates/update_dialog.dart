import 'package:flutter/material.dart';
import 'package:horas_trabajo/services/update_service.dart';

/// Diálogo modal que informa de una versión nueva y permite descargar e
/// instalar el APK desde GitHub, mostrando el progreso en vivo.
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.info});

  final UpdateInfo info;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _descargando = false;
  int _descargados = 0;
  int _total = 0;
  String? _error;

  UpdateInfo get _info => widget.info;

  double get _progreso =>
      _total > 0 ? (_descargados / _total).clamp(0.0, 1.0) : 0;

  String get _tamano {
    final mb = _info.apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _actualizar() async {
    setState(() {
      _descargando = true;
      _error = null;
      _descargados = 0;
      _total = _info.apkSizeBytes;
    });
    try {
      final ruta = await UpdateService.instance.descargarAPK(
        _info,
        onProgress: (d, t) {
          if (mounted) {
            setState(() {
              _descargados = d;
              if (t > 0) _total = t;
            });
          }
        },
      );
      if (!mounted) return;
      final error = await UpdateService.instance.instalar(ruta);
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _descargando = false;
          _error = 'No se pudo abrir el instalador: $error';
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _descargando = false;
          _error = 'Error al descargar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notas = _info.notes.trim();

    Widget contenido;
    if (!_descargando) {
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.download, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text('$_tamano para descargar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall),
            ),
          ]),
          if (notas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Novedades', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(notas,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall),
            ),
          ],
        ],
      );
    } else {
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progreso,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${(_progreso * 100).round()}%', style: theme.textTheme.labelLarge),
          ]),
          const SizedBox(height: 8),
          Text(
            _progreso >= 1
                ? 'Abriendo el instalador…'
                : 'Descargando ${_info.apkSizeBytes > 0 ? (_descargados ~/ (1024 * 1024)) : 0} de $_tamano…',
            style: theme.textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
          ],
        ],
      );
    }

    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
        child: Icon(Icons.system_update_alt, color: scheme.primary, size: 28),
      ),
      title: Text(
        'Versión ${_info.versionEtiqueta} disponible',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: contenido,
      actions: [
        if (_descargando)
          const TextButton(onPressed: null, child: Text('Espera…'))
        else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Más tarde'),
          ),
          FilledButton.icon(
            onPressed: _actualizar,
            icon: const Icon(Icons.download_done, size: 20),
            label: const Text('Actualizar ahora'),
          ),
        ],
      ],
    );
  }
}