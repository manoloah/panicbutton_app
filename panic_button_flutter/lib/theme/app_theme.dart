import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette
  static const Color primaryColor = Color(0xFF132737); // deep blue
  static const Color secondaryColor = Color(0xFFB0B0B0);
  static const Color accentColor = Color(0xFFFFFFFF);
  static const Color buttonColor = Color(0xFF00B383); //0xFF00B383
  static const Color darkButtonColor = Color(0xFF1A392A);
  static const Color disabledColor = Color(0xFF444444);

  /// Global theme (dark mode look & feel)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // ----- COLOR SCHEME -----
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        background: primaryColor, // full‑screen areas
        surface: primaryColor, // cards, scaffold, etc.
        error: Colors.red, // defaults to 0xFFB00020 in dark, override if needed
      ),

      scaffoldBackgroundColor:
          primaryColor, // fallback in case a widget skips ColorScheme

      // ----- TYPOGRAPHY -----
      textTheme: TextTheme(
        displayLarge: GoogleFonts.unbounded(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
        titleLarge: GoogleFonts.unbounded(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
        titleMedium: GoogleFonts.unbounded(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
        bodyLarge: GoogleFonts.cabin(fontSize: 16, color: secondaryColor),
        bodyMedium: GoogleFonts.cabin(fontSize: 14, color: secondaryColor),
      ),

      // ----- ELEVATED BUTTONS -----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ----- TEXT‑FIELDS -----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
        ),
        labelStyle: const TextStyle(color: secondaryColor),
      ),
    );
  }
}
