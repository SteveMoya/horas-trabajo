import 'package:flutter/material.dart';
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/core/widgets/staggered_fade_in.dart';
import 'package:horas_trabajo/core/widgets/state_views.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/features/history/session_detail_sheet.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: app.sesiones.isEmpty
          ? const _Vacio()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: app.sesiones.length,
              itemBuilder: (context, i) => StaggeredFadeIn(
                index: i,
                child: _TarjetaSesion(
                  sesion: app.sesiones[i],
                  nuevoActiva: app.sesiones[i].enProgreso,
                  onTap: () => _abrirDetalle(context, app, app.sesiones[i]),
                  onEliminar: () => app.eliminarSesion(app.sesiones[i].id),
                ),
              ),
            ),
    );
  }

  void _abrirDetalle(
    BuildContext context,
    AppState app,
    WorkSession sesion,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SessionDetailSheet(app: app, sesion: sesion),
      ),
    );
  }
}

class _TarjetaSesion extends StatelessWidget {
  const _TarjetaSesion({
    required this.sesion,
    required this.nuevoActiva,
    required this.onTap,
    required this.onEliminar,
  });

  final WorkSession sesion;
  final bool nuevoActiva;
  final VoidCallback onTap;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fin = sesion.fin;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: sesion.enProgreso
              ? scheme.tertiaryContainer
              : scheme.surfaceContainerHighest,
          child: Icon(
            sesion.enProgreso ? Icons.play_arrow : Icons.check,
            color: sesion.enProgreso
                ? scheme.onTertiaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        title: Text(Fmt.fechaLarga(sesion.inicio),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${Fmt.horaCorta(sesion.inicio)} – ${fin == null ? 'en curso' : Fmt.horaCorta(fin)} · '
          '${Fmt.duracionExtendida(sesion.duracion)}',
        ),
        isThreeLine: false,
        onTap: onTap,
        trailing: IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete_outline),
          onPressed: onEliminar,
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) => const EmptyState(
        titulo: 'Sin registros',
        mensaje: 'Marca tu entrada en la pestaña «Marcar»',
      );
}