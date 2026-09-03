import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas_trabajo/core/theme/pixel_shapes.dart';

/// Paletas de color primario disponibles (Material 3 genera el resto).
class ThemePalettes {
  static const List<Color> seeds = [
    Color(0xFF1565C0), // Azul — color de marca (Horas Trabajo)
    Color(0xFF00696D), // Teal
    Color(0xFF6750A4), // Morado M3 por defecto
    Color(0xFF2E7D32), // Verde
    Color(0xFFC62828), // Rojo
    Color(0xFFAD1457), // Rosa
    Color(0xFFEF6C00), // Naranja
    Color(0xFF283593), // Índigo
    Color(0xFF00838F), // Cian
    Color(0xFF4E342E), // Café/warm neutral
  ];

  static String nombre(int index) {
    const names = [
      'Azul (marca)', 'Teal', 'Morado', 'Verde', 'Rojo',
      'Rosa', 'Naranja', 'Índigo', 'Cian', 'Neutral',
    ];
    return names[index.clamp(0, names.length - 1)];
  }
}

/// Construcción de los temas Material 3 (claro y oscuro).
class AppTheme {
  static ThemeData light(Color seed) => _build(Brightness.light, seed);
  static ThemeData dark(Color seed) => _build(Brightness.dark, seed);

  static ThemeData _build(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );

    final text = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        // Esquinas continuas ("squircle") en vez del arco circular por
        // defecto de Material — la seña visual de Material You / Pixel.
        shape: const SquircleBorder(radius: PixelRadii.large),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: const SquircleBorder(radius: PixelRadii.medium),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.6),
        // Más aire vertical entre el label flotante y el texto ingresado
        // (el valor por defecto de Material deja ambos casi pegados).
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PixelRadii.small),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PixelRadii.small),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: SquircleBorder(radius: PixelRadii.small),
      ),
      dialogTheme: const DialogThemeData(
        shape: SquircleBorder(radius: PixelRadii.large),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(PixelRadii.large),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: SquircleBorder(radius: PixelRadii.large),
      ),
      chipTheme: ChipThemeData(
        shape: const SquircleBorder(radius: PixelRadii.small),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: const SquircleBorder(radius: PixelRadii.medium),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}