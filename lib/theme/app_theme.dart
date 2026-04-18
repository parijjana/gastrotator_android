import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// [SYSTEM INTEGRITY]: This theme defines the "Culinary Curator" design system.
/// DO NOT REGRESS: Primary #944A00, Surface #FCF9F8.
/// Headlines must use Noto Serif, Body must use Manrope.
class AppTheme {
  static ThemeData light(Color primaryColor) => _base(primaryColor, Brightness.light);
  static ThemeData dark(Color primaryColor) => _base(primaryColor, Brightness.dark);

  static ThemeData _base(Color primaryColor, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        surface: isDark ? const Color(0xFF1C1B1B) : const Color(0xFFFCF9F8),
        onSurface: isDark ? const Color(0xFFFCF9F8) : const Color(0xFF1C1B1B),
      ),
      textTheme: TextTheme(
        displayMedium: GoogleFonts.notoSerif(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.notoSerif(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.notoSerif(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.notoSerif(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(color: Colors.grey[400]),
      ),
    );
  }

  // Legacy getter for backward compatibility if needed
  static ThemeData get vibrantTheme => light(const Color(0xFF944A00));
}
