import 'package:flutter/material.dart';

/// Ilustraciones SVG del sistema de diseño. Cada una vive en
/// `assets/illustrations/<archivo>.svg` con tokens de color (`{{token}}`)
/// que [AppIllustration] sustituye según el tema activo — así toda pieza
/// se ve coherente sin importar la semilla de color u modo claro/oscuro
/// que el usuario elija.
enum AppIllustrationAsset {
  welcome('welcome'),
  empty('empty'),
  error('error'),
  success('success'),
  loading('loading'),
  noConnection('no_connection'),
  track('track'),
  calculate('calculate'),
  reports('reports'),
  support('support');

  const AppIllustrationAsset(this._archivo);

  final String _archivo;

  String get assetPath => 'assets/illustrations/$_archivo.svg';
}

/// Acento de café — constante entre temas para que la taza y los granos se
/// reconozcan como tales sin importar la semilla de color elegida.
class IllustrationColors {
  const IllustrationColors._();

  static const coffee = Color(0xFF6F4E37);
  static const coffeeLight = Color(0xFFC9A27E);
}

/// Mapa de reemplazos `token` → color a partir del [ColorScheme] activo.
/// Las formas estructurales (papel, siluetas, escritorio) usan tonos
/// neutros de superficie para no chocar con ninguna semilla; solo los
/// acentos (taza, check, confeti) toman el color de marca.
Map<String, Color> illustrationTokens(ColorScheme scheme) => {
      'outline': scheme.outlineVariant,
      'onSurfaceVariant': scheme.onSurfaceVariant,
      'surface': scheme.surfaceContainerHighest,
      'surfaceLow': scheme.surfaceContainerLow,
      'primary': scheme.primary,
      'primaryContainer': scheme.primaryContainer,
      'onPrimaryContainer': scheme.onPrimaryContainer,
      'tertiary': scheme.tertiary,
      'tertiaryContainer': scheme.tertiaryContainer,
      'error': scheme.error,
      'coffee': IllustrationColors.coffee,
      'coffeeLight': IllustrationColors.coffeeLight,
    };

/// Color opaco a hex `#rrggbb` para incrustar en el SVG plantilla.
String colorToHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
