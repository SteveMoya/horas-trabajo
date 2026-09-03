import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Información de una actualización disponible (un release de GitHub).
class UpdateInfo {
  const UpdateInfo({
    required this.tag,
    required this.version,
    required this.apkUrl,
    required this.apkSizeBytes,
    required this.notes,
    required this.releasedAt,
    required this.prerelease,
  });

  /// Tag del release, p. ej. `v0.7.0`.
  final String tag;

  /// Versión semántica sin el prefijo "v", p. ej. `0.7.0`.
  final String version;

  /// URL directa del APK para descargar.
  final String apkUrl;

  /// Tamaño del APK en bytes (para mostrar el progreso).
  final int apkSizeBytes;

  /// Notas de la release (changelog).
  final String notes;

  final DateTime? releasedAt;

  final bool prerelease;

  String get versionEtiqueta => prerelease ? '$version (beta)' : version;
}

/// Compara versiones semánticas `x.y.z` (sin considerar el prefijo "v" ni el
/// número de build, que no determina si hay que actualizar).
int compararVersiones(String a, String b) {
  final pa = _parse(a);
  final pb = _parse(b);
  for (final key in ['mayor', 'menor', 'parche']) {
    final va = pa[key] ?? 0;
    final vb = pb[key] ?? 0;
    if (va != vb) return va.compareTo(vb);
  }
  return 0;
}

Map<String, int?> _parse(String v) {
  var s = v.trim();
  if (s.startsWith('v')) s = s.substring(1);
  final sinMeta = s.split('+').first;
  final pre = s.contains('+') ? s.split('+').last : null;
  final partes = sinMeta.split('.');
  int? n(int i) =>
      partes.length > i && int.tryParse(partes[i].split('-').first) != null
          ? int.tryParse(partes[i].split('-').first)
          : null;
  return {
    'mayor': n(0),
    'menor': n(1),
    'parche': n(2),
    'build': pre != null ? int.tryParse(pre) : null,
  };
}

/// Revisa y descarga actualizaciones del APK desde los releases de GitHub.
class UpdateService {
  const UpdateService._();
  static const instance = UpdateService._();

  static const _repo = 'SteveMoya/horas-trabajo';
  static const _api = 'https://api.github.com/repos/$_repo/releases';

  /// Revisa si hay una versión [UpdateInfo] más nueva que la instalada.
  ///
  /// Devuelve `null` si no hay actualización o si la revisión falla (sin
  /// lanzar: es best-effort y no debe romper el arranque). La versión
  /// instalada se obtiene de `PackageInfo`.
  Future<UpdateInfo?> verificar({String userAgent = 'HorasTrabajo/1.0'}) async {
    try {
      return await _verificarCore(userAgent);
    } catch (_) {
      return null;
    }
  }

  Future<UpdateInfo?> _verificarCore(String userAgent) async {
    final resp = await http
        .get(Uri.parse('$_api?per_page=1'), headers: {'User-Agent': userAgent})
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) return null;
    final releases = jsonDecode(resp.body) as List<dynamic>;
    if (releases.isEmpty) return null;
    final r = releases.first as Map<String, dynamic>;

    final tag = (r['tag_name'] as String?) ?? '';
    final apkAsset = (r['assets'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((a) => ((a['name'] as String?) ?? '').endsWith('.apk'))
        .toList();
    if (tag.isEmpty || apkAsset.isEmpty) return null;

    final info = UpdateInfo(
      tag: tag,
      version: _normalizar(tag),
      apkUrl: (apkAsset.first['browser_download_url'] as String?) ?? '',
      apkSizeBytes: (apkAsset.first['size'] as num?)?.toInt() ?? 0,
      notes: (r['body'] as String?) ?? '',
      releasedAt: r['published_at'] == null
          ? null
          : DateTime.tryParse(r['published_at'] as String),
      prerelease: (r['prerelease'] as bool?) ?? false,
    );
    if (info.apkUrl.isEmpty) return null;

    final PackageInfo pi = await PackageInfo.fromPlatform();
    final actual = _normalizar('${pi.version}+${pi.buildNumber}');
    if (compararVersiones(info.version, actual) > 0) return info;
    return null;
  }

  /// `v0.7.0` → `0.7.0` (quita el prefijo "v" del tag y el build si va).
  String _normalizar(String tag) {
    var s = tag.trim();
    if (s.startsWith('v')) s = s.substring(1);
    return s.contains('+') ? s.split('+').first : s;
  }

  /// Descarga el APK a un archivo temporal y devuelve su ruta.
  ///
  /// [onProgress] recibe el progreso acumulado (bytes descargados) para poder
  /// actualizar una barra en la UI.
  Future<String> descargarAPK(
    UpdateInfo info, {
    void Function(int bytesDescargados, int totalBytes)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/horas-trabajo-${info.tag}.apk');
    // Reusa una descarga ya completada para no volver a bajar 60 MB.
    if (archivo.existsSync() && archivo.lengthSync() == info.apkSizeBytes) {
      onProgress?.call(info.apkSizeBytes, info.apkSizeBytes);
      return archivo.path;
    }

    final request = http.Request('GET', Uri.parse(info.apkUrl));
    final streamed = await request.send();
    if (streamed.statusCode != 200) {
      throw HttpException('Fallo al descargar: HTTP ${streamed.statusCode}');
    }

    final sink = archivo.openSync(mode: FileMode.write);
    final total = info.apkSizeBytes > 0 ? info.apkSizeBytes : streamed.contentLength ?? 0;
    var descargados = 0;
    try {
      await for (final chunk in streamed.stream) {
        sink.writeFrom(chunk);
        descargados += chunk.length;
        onProgress?.call(descargados, total);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
    return archivo.path;
  }

  /// Resultado del intento de abrir el instalador del APK.
  static const _canal = MethodChannel('horas_trabajo/instalador');

  /// Abre el instalador de paquetes con el APK [ruta] para instalar la
  /// actualización. En Android usa el canal nativo propio, que además detecta
  /// si falta el permiso de "Instalar apps desconocidas" (causa habitual de
  /// que la instalación no arranque sin avisar) y cae a `open_filex` si el
  /// canal no está disponible (p. ej. iOS).
  Future<InstalacionResumen> instalar(String ruta) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final res = await _canal.invokeMethod<String>('instalar', {'ruta': ruta});
        switch (res) {
          case 'ok':
            return const InstalacionResumen(InstalacionResultado.exito);
          case 'permiso':
            return const InstalacionResumen(
              InstalacionResultado.permisoRequerido,
              'Permite instalar apps de este origen para poder actualizar. '
                  'Toca "Permitir instalación" para abrir los ajustes.',
            );
          case null:
            return const InstalacionResumen(
              InstalacionResultado.error, 'El instalador no respondió.');
          default:
            final detalle = res.startsWith('error:')
                ? res.substring('error:'.length)
                : res;
            return InstalacionResumen(InstalacionResultado.error, detalle);
        }
      } catch (_) {
        // Canal no disponible (p. ej. build muy antiguo): fallback.
        return _instalarConOpenFilex(ruta);
      }
    }
    return _instalarConOpenFilex(ruta);
  }

  Future<InstalacionResumen> _instalarConOpenFilex(String ruta) async {
    final res = await OpenFilex.open(
        ruta, type: 'application/vnd.android.package-archive');
    if (res.type == ResultType.done) {
      return const InstalacionResumen(InstalacionResultado.exito);
    }
    return InstalacionResumen(InstalacionResultado.error, res.message);
  }

  /// ¿Está permitido instalar apps de este origen en Android (8+)?
  static Future<bool> puedeInstalar() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        return await _canal.invokeMethod<bool>('puedeInstalar') ?? true;
      } catch (_) {
        return true;
      }
    }
    return true;
  }

  /// Abre los ajustes de "Instalar apps desconocidas" de la app.
  static Future<void> abrirAjustesInstalacion() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _canal.invokeMethod('abrirAjustesInstalacion');
      } catch (_) {/* sin ajustes accesibles */}
    }
  }
}

/// Resultado de intentar abrir el instalador del APK.
enum InstalacionResultado { exito, error, permisoRequerido }

class InstalacionResumen {
  const InstalacionResumen(this.resultado, [this.mensaje]);
  final InstalacionResultado resultado;
  final String? mensaje;
}