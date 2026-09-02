import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paletas de color primario disponibles (Material 3 genera el resto).
class ThemePalettes {
  static const List<Color> seeds = [
    Color(0xFF6750A4), // Morado M3 por defecto
    Color(0xFF00696D), // Teal
    Color(0xFF1565C0), // Azul
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
      'Morado', 'Teal', 'Azul', 'Verde', 'Rojo',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.4 : 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}