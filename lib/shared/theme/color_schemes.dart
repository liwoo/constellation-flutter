import 'package:flutter/material.dart';

/// App color palette based on the constellation UI design
class AppColors {
  const AppColors._();

  // Primary gradient colors
  static const Color primaryPurple = Color(0xFF9C27B0); // Purple 700
  static const Color primaryNavy = Color(0xFF1A237E); // Indigo 900
  static const Color primaryDarkPurple = Color(0xFF6A1B9A); // Purple 800

  // Accent colors
  static const Color accentGold = Color(0xFFFFD700); // Gold
  static const Color accentPink = Color(0xFFE91E63); // Pink 500
  static const Color accentOrange = Color(0xFFFF9800); // Orange 500
  static const Color accentYellow = Color(0xFFFFEB3B); // Yellow 500

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyMedium = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF424242);

  // Background overlays
  static const Color darkOverlay = Color(0x4D000000); // 30% opacity
  static const Color lightOverlay = Color(0x1AFFFFFF); // 10% opacity

  // Letter bubble
  static const Color letterBubble = Color(0xF2FFFFFF); // 95% opacity
  static const Color letterBubbleSelected = Color(0xFFFFFFFF); // 100% opacity
}

/// Light color scheme for the app
final ColorScheme lightColorScheme = ColorScheme.light(
  primary: AppColors.primaryPurple,
  secondary: AppColors.accentGold,
  tertiary: AppColors.accentPink,
  surface: AppColors.white,
  background: AppColors.white,
  error: Colors.red.shade700,
  onPrimary: AppColors.white,
  onSecondary: AppColors.black,
  onSurface: AppColors.black,
  onBackground: AppColors.black,
  onError: AppColors.white,
);

/// Dark color scheme for the app (matching the UI design)
final ColorScheme darkColorScheme = ColorScheme.dark(
  primary: AppColors.primaryPurple,
  secondary: AppColors.accentGold,
  tertiary: AppColors.accentPink,
  surface: AppColors.primaryNavy,
  background: AppColors.primaryNavy,
  error: Colors.red.shade400,
  onPrimary: AppColors.white,
  onSecondary: AppColors.black,
  onSurface: AppColors.white,
  onBackground: AppColors.white,
  onError: AppColors.white,
);
