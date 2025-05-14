// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ocean breath colors theme extension
@immutable
class BreathColors extends ThemeExtension<BreathColors> {
  final Color oceanDeep;
  final Color oceanMid;
  final Color oceanSurface;

  const BreathColors({
    required this.oceanDeep,
    required this.oceanMid,
    required this.oceanSurface,
  });

  @override
  ThemeExtension<BreathColors> copyWith({
    Color? oceanDeep,
    Color? oceanMid,
    Color? oceanSurface,
  }) {
    return BreathColors(
      oceanDeep: oceanDeep ?? this.oceanDeep,
      oceanMid: oceanMid ?? this.oceanMid,
      oceanSurface: oceanSurface ?? this.oceanSurface,
    );
  }

  @override
  ThemeExtension<BreathColors> lerp(
    covariant ThemeExtension<BreathColors>? other,
    double t,
  ) {
    if (other is! BreathColors) {
      return this;
    }
    return BreathColors(
      oceanDeep: Color.lerp(oceanDeep, other.oceanDeep, t)!,
      oceanMid: Color.lerp(oceanMid, other.oceanMid, t)!,
      oceanSurface: Color.lerp(oceanSurface, other.oceanSurface, t)!,
    );
  }
}

/// ─────────────────────────────────────────────────────────────
///  BreathManu Brand – Dark Theme
///  All colour codes & font choices taken directly from the
///  "Color & Brand – The BreathManu" document. :contentReference[oaicite:0]{index=0}
/// ─────────────────────────────────────────────────────────────
class AppTheme {
  // Brand colours
  static const _bg = Color(0xFF132737); // background
  static const _white = Color(0xFFFFFFFF); // main text
  static const _altText = Color(0xFFB0B0B0); // alt / secondary text
  static const _darkerGray = Color(0xFF525252); // muted text
  static const _lightBlue = Color(0xFF030133); // secondary‑alt
  static const _greenAccent = Color(0xFF00B383); // highlights / CTAs
  static const _purpleAccent = Color(0xFF9049E7); // alt accent
  static const _error = Color(0xFFFF4500); // error
  static const _errorLight = Color(0xFFEF9A9A); // error light

  // Ocean breath colors
  static const _oceanDeep = Color(0xFF1A5276); // Deep blue ocean
  static const _oceanMid = Color(0xFF2E86C1); // Mid-level ocean blue
  static const _oceanSurface = Color(0xFF85C1E9); // Surface/foam blue

  // Single dark theme
  static ThemeData dark() {
    // ---- Colour scheme --------------------------------------------------
    const colors = ColorScheme(
      brightness: Brightness.dark,
      primary: _greenAccent, // default CTA
      onPrimary: _bg, // text/icon on green buttons
      secondary: _purpleAccent, // optional purple accent
      onSecondary: _bg,
      surface: Color(0xFF1E3244), // card/dialog surface
      onSurface: _white,
      error: _error,
      onError: _white,
    );

    // ---- Typography -----------------------------------------------------
    final textTheme = TextTheme(
      // Titles
      displayLarge: GoogleFonts.unbounded(
        fontWeight: FontWeight.bold,
        fontSize: 36,
        color: _white,
      ),
      displayMedium: GoogleFonts.unbounded(
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: _white,
      ),
      headlineLarge: GoogleFonts.unbounded(
        fontWeight: FontWeight.bold,
        fontSize: 34,
        color: _white,
      ),
      headlineMedium: GoogleFonts.unbounded(
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: _white,
      ),
      headlineSmall: GoogleFonts.unbounded(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: _white,
      ),

      // Body
      bodyLarge: GoogleFonts.cabin(
        fontSize: 16,
        color: _white,
      ),
      bodyMedium: GoogleFonts.cabin(
        fontSize: 14,
        color: _altText,
      ),

      // Captions / comments
      labelSmall: GoogleFonts.cabin(
        fontStyle: FontStyle.italic,
        fontSize: 12,
        color: _darkerGray,
      ),
    );

    // ---- Component themes ----------------------------------------------
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,

      // Green CTA buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cabin(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // White "secondary" buttons (gray text)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: _white,
          foregroundColor: _altText,
          side: BorderSide(color: _altText.withAlpha((.3 * 255).toInt())),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cabin(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Text buttons (links)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _greenAccent,
          textStyle: GoogleFonts.cabin(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.unbounded(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: _white,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: _lightBlue.withAlpha((.4 * 255).toInt())),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _greenAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        hintStyle: TextStyle(color: _altText),
      ),

      // Theme extensions
      extensions: const [
        BreathColors(
          oceanDeep: _oceanDeep,
          oceanMid: _oceanMid,
          oceanSurface: _oceanSurface,
        ),
      ],
    );
  }
}
