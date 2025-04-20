import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF132737);
  static const Color secondaryColor = Color(0xFFB0B0B0);
  static const Color accentColor = Color(0xFFFFFFFF);
  static const Color buttonColor = Color(0xFF00B383);
  static const Color darkButtonColor = Color(0xFF1A392A);
  static const Color disabledColor = Color(0xFF444444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: accentColor,
        background: primaryColor,
        error: Colors.red.shade400,
      ),
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
        bodyLarge: GoogleFonts.cabin(
          fontSize: 16,
          color: secondaryColor,
        ),
        bodyMedium: GoogleFonts.cabin(
          fontSize: 14,
          color: secondaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        labelStyle: TextStyle(color: secondaryColor),
      ),
    );
  }
} 