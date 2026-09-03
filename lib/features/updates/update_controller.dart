import 'package:flutter/material.dart';
import 'package:horas_trabajo/features/updates/update_dialog.dart';
import 'package:horas_trabajo/services/notifications_service.dart';
import 'package:horas_trabajo/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Orquesta la revisión de actualizaciones: decide cuándo notificar/mostrar el
/// diálogo (una vez por versión) y expone el [navigatorKey] global para poder
/// abrir el diálogo desde una notificación aunque la UI aún no esté lista.
class UpdateController {
  UpdateController._();
  static final instance = UpdateController._();

  /// Navigator global (lo registra `HiApp`) para abrir el diálogo de
  /// actualización incluso desde un arranque en primer plano o una
  /// notificación.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const _prefsUltimaAvisada = 'update_ultima_avisada';

  /// Mínimo entre revisiones en red (evita golpear la API de GitHub en cada
  /// "resume"). El arranque frío siempre corre la primera.
  static const _throttle = Duration(minutes: 3);

  DateTime? _ultimaVerificacion;
  UpdateInfo? _pendiente;

  UpdateInfo? get pendiente => _pendiente;

  /// Revisa si hay una actualización y, si la hay, la notifica y ofrece
  /// actualizar. Se llama al arrancar y al volver a primer plano; `fromNotificacion`
  /// fuerza mostrar el diálogo (se invoca al tocar la notificación).
  Future<UpdateInfo?> verificar({bool fromNotificacion = false}) async {
    final ahoraVer = DateTime.now();
    if (!fromNotificacion &&
        _ultimaVerificacion != null &&
        ahoraVer.difference(_ultimaVerificacion!) < _throttle) {
      // Revisión en red muy reciente: devuelve lo ya conocido sin golpear la red.
      return _pendiente;
    }
    _ultimaVerificacion = ahoraVer;

    final info = await UpdateService.instance.verificar();
    if (info == null) return null;
    _pendiente = info;

    final prefs = await SharedPreferences.getInstance();
    final ultima = prefs.getString(_prefsUltimaAvisada);
    final esNueva = ultima != info.version;

    if (esNueva) {
      await prefs.setString(_prefsUltimaAvisada, info.version);
      // Notificación "actualización disponible" (tocar → abre el diálogo).
      await NotificationsService.mostrarActualizacion(version: info.versionEtiqueta);
    }

    if (fromNotificacion || esNueva) {
      _mostrarDialogo(info);
    }
    return info;
  }

  /// Abre el diálogo de actualización (si ya se conocía que hay update).
  Future<void> mostrarDialogoDesdeNotificacion() async {
    if (_pendiente != null) {
      _mostrarDialogo(_pendiente!);
      return;
    }
    await verificar(fromNotificacion: true);
  }

  void _mostrarDialogo(UpdateInfo info) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context, rootNavigator: true).push(
      DialogRoute<void>(
        context: context,
        builder: (_) => UpdateDialog(
          key: ValueKey('update-${info.tag}'),
          info: info,
        ),
      ),
    );
  }
}