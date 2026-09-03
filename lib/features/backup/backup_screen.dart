import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:horas_trabajo/services/backup_service.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

/// Copia de seguridad y exportación: todo local, sin backend ni nube propia.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backup = BackupService();
  bool _procesando = false;

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await accion();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo completar la operación: $e')),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _exportarJson() =>
      _ejecutar(() => _backup.exportarBackupJson());

  Future<void> _exportarCsv(AppState app) =>
      _ejecutar(() => _backup.exportarCsv(app.motor));

  Future<void> _restaurar(AppState app) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 34),
        title: const Text('¿Restaurar copia de seguridad?'),
        content: const Text(
          'Esto reemplaza TODO tu perfil, reglas, lugar de trabajo e '
          'historial actuales por los del archivo elegido. No se puede '
          'deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, reemplazar todo'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    await _ejecutar(() async {
      final archivo = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (archivo == null) return;

      final bytes = await archivo.readAsBytes();
      final ok = await _backup.restaurarBackupJson(bytes);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo no es una copia de seguridad válida'),
          ),
        );
        return;
      }
      await app.cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copia de seguridad restaurada ✅')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de seguridad y exportación')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Todo se guarda y comparte 100% desde tu dispositivo: '
                      'no hay servidor ni cuenta en la nube de la app.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: const Text('Exportar copia de seguridad completa'),
                  subtitle: const Text(
                    'Perfil, reglas, lugar de trabajo e historial en un .json',
                  ),
                  onTap: _procesando ? null : _exportarJson,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Exportar historial a CSV'),
                  subtitle: const Text('Una fila por jornada, con el desglose de horas'),
                  onTap: _procesando ? null : () => _exportarCsv(app),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.restore,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Restaurar desde archivo'),
              subtitle: const Text(
                'Reemplaza todos tus datos actuales por los de un .json exportado antes',
              ),
              onTap: _procesando ? null : () => _restaurar(app),
            ),
          ),
          if (_procesando) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
