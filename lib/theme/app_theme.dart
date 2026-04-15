import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// [SYSTEM INTEGRITY]: This theme defines the "Culinary Curator" design system.
/// DO NOT REGRESS: Primary #944A00, Surface #FCF9F8.
/// Headlines must use Noto Serif, Body must use Manrope.
class AppTheme {
  static ThemeData get vibrantTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF944A00),
        brightness: Brightness.light,
        primary: const Color(0xFF944A00), // Culinary Curator "Heat Signature"
        onPrimary: Colors.white,
        secondary: const Color(0xFF4E6073),
        tertiary: const Color(0xFF3B3B3B),
        surface: const Color(0xFFFCF9F8),
        onSurface: const Color(0xFF1C1B1B),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF6F3F2),
        surfaceContainer: const Color(0xFFF0EDEC),
        surfaceContainerHigh: const Color(0xFFEBE7E7),
        surfaceContainerHighest: const Color(0xFFE5E2E1),
      ),
      textTheme: TextTheme(
        // High-impact Editorial Masthead
        displayMedium: GoogleFonts.notoSerif(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1C1B1B),
          letterSpacing: -0.5,
          height: 1.1,
        ),
        headlineLarge: GoogleFonts.notoSerif(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1B1B),
        ),
        titleLarge: GoogleFonts.notoSerif(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1B1B),
        ),
        // Instructional Body Text
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          color: const Color(0xFF1C1B1B),
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          color: const Color(0xFF1C1B1B),
          height: 1.5,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          color: const Color(0xFF474747),
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF944A00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Sharp radius
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC6C6C6), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC6C6C6), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF944A00), width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(color: Colors.grey[400]),
      ),
    );
  }
}
