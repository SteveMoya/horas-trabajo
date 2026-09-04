import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:horas_trabajo/core/illustrations/app_illustrations.dart';

/// Ilustración del sistema de diseño: carga el SVG plantilla de [asset] y
/// sustituye sus tokens de color (`{{token}}`) según el tema activo — ver
/// [illustrationTokens]. Cachea la plantilla cruda por [asset] para que
/// usos repetidos de la misma ilustración no vuelvan a leer el archivo.
class AppIllustration extends StatelessWidget {
  const AppIllustration(this.asset, {super.key, this.size, this.semanticLabel});

  final AppIllustrationAsset asset;
  final double? size;

  /// Si es `null`, la ilustración se trata como puramente decorativa y se
  /// excluye del árbol de accesibilidad.
  final String? semanticLabel;

  static final _plantillas = <String, String>{};

  static Future<String> _plantilla(String path) async {
    final cacheada = _plantillas[path];
    if (cacheada != null) return cacheada;
    final cruda = await rootBundle.loadString(path);
    _plantillas[path] = cruda;
    return cruda;
  }

  @override
  Widget build(BuildContext context) {
    final path = asset.assetPath;
    final cacheada = _plantillas[path];
    if (cacheada != null) return _render(context, cacheada);

    return FutureBuilder<String>(
      future: _plantilla(path),
      builder: (context, snapshot) {
        final plantilla = snapshot.data;
        if (plantilla == null) return SizedBox(width: size, height: size);
        return _render(context, plantilla);
      },
    );
  }

  Widget _render(BuildContext context, String plantilla) {
    final scheme = Theme.of(context).colorScheme;
    var svg = plantilla;
    for (final entry in illustrationTokens(scheme).entries) {
      svg = svg.replaceAll('{{${entry.key}}}', colorToHex(entry.value));
    }
    final picture = SvgPicture.string(
      svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    if (semanticLabel == null) return ExcludeSemantics(child: picture);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(child: picture),
    );
  }
}
