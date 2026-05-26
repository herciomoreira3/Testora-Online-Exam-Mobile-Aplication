import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  static TextStyle get titleLarge => GoogleFonts.inter(
        color: AppColors.text,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        color: AppColors.text,
        fontSize: 16,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        color: AppColors.textLight,
        fontSize: 14,
      );
}
