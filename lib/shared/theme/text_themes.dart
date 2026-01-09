import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/shared/theme/color_schemes.dart';

/// Text theme configuration for the app
/// Uses Orbitron for display/headlines (sci-fi feel) and Exo 2 for body text (readability)
class AppTextThemes {
  const AppTextThemes._();

  /// Light text theme
  static TextTheme get lightTextTheme => TextTheme(
        // Display styles - Orbitron
        displayLarge: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),

        // Headline styles - Orbitron
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),

        // Title styles - Exo 2
        titleLarge: GoogleFonts.exo2(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        titleMedium: GoogleFonts.exo2(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),
        titleSmall: GoogleFonts.exo2(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
        ),

        // Body styles - Exo 2
        bodyLarge: GoogleFonts.exo2(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),
        bodyMedium: GoogleFonts.exo2(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),
        bodySmall: GoogleFonts.exo2(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),

        // Label styles - Exo 2
        labelLarge: GoogleFonts.exo2(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.exo2(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.exo2(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.black,
          letterSpacing: 0.5,
        ),
      );

  /// Dark text theme
  static TextTheme get darkTextTheme => TextTheme(
        // Display styles - Orbitron
        displayLarge: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),

        // Headline styles - Orbitron
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),

        // Title styles - Exo 2
        titleLarge: GoogleFonts.exo2(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleMedium: GoogleFonts.exo2(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        titleSmall: GoogleFonts.exo2(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),

        // Body styles - Exo 2
        bodyLarge: GoogleFonts.exo2(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.white,
        ),
        bodyMedium: GoogleFonts.exo2(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.white,
        ),
        bodySmall: GoogleFonts.exo2(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.white,
        ),

        // Label styles - Exo 2
        labelLarge: GoogleFonts.exo2(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.exo2(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.exo2(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
          letterSpacing: 0.5,
        ),
      );
}
