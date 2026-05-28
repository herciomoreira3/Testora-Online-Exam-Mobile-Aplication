import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00288E);
  static const Color primaryContainer = Color(0xFF1E40AF);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFF10B981);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFDC2626);
  static const Color successColor = accentColor;
  static const Color textColor = Color(0xFF1E2937);
  static const Color subTextColor = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        error: errorColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.inter(color: textColor, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: subTextColor, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: textColor),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: GoogleFonts.inter(color: subTextColor),
        hintStyle: GoogleFonts.inter(color: subTextColor.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
