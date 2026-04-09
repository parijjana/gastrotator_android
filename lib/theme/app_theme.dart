import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get vibrantTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF8C00),
        brightness: Brightness.light,
        primary: const Color(0xFFFF8C00), // Vibrant Orange
        onPrimary: Colors.white,
        secondary: const Color(0xFF32CD32), // Lime Green
        tertiary: const Color(0xFFFFD700), // Sunny Yellow
        surface: const Color(0xFFFFF5ED),
        onSurface: const Color(0xFF452800),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFFFEEDF),
        surfaceContainer: const Color(0xFFFFE4C9),
        surfaceContainerHigh: const Color(0xFFFFDDBA),
        surfaceContainerHighest: const Color(0xFFFFD6AB),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF452800),
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF452800),
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF452800),
        ),
        bodyLarge: GoogleFonts.beVietnamPro(
          color: const Color(0xFF452800),
        ),
        bodyMedium: GoogleFonts.beVietnamPro(
          color: const Color(0xFF452800),
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C00),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.beVietnamPro(color: Colors.grey[400]),
      ),
    );
  }
}
