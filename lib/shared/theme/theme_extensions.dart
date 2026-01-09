import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';

/// Theme extension for spacing values
class SpacingThemeExtension extends ThemeExtension<SpacingThemeExtension> {
  const SpacingThemeExtension({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  @override
  SpacingThemeExtension copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return SpacingThemeExtension(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  SpacingThemeExtension lerp(SpacingThemeExtension? other, double t) {
    if (other is! SpacingThemeExtension) return this;
    return SpacingThemeExtension(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }

  static SpacingThemeExtension get defaultSpacing => const SpacingThemeExtension(
        xs: AppSpacing.xs,
        sm: AppSpacing.sm,
        md: AppSpacing.md,
        lg: AppSpacing.lg,
        xl: AppSpacing.xl,
        xxl: AppSpacing.xxl,
      );
}

/// Theme extension for border radius values
class BorderRadiusThemeExtension
    extends ThemeExtension<BorderRadiusThemeExtension> {
  const BorderRadiusThemeExtension({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  @override
  BorderRadiusThemeExtension copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return BorderRadiusThemeExtension(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  BorderRadiusThemeExtension lerp(BorderRadiusThemeExtension? other, double t) {
    if (other is! BorderRadiusThemeExtension) return this;
    return BorderRadiusThemeExtension(
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }

  static BorderRadiusThemeExtension get defaultBorderRadius =>
      const BorderRadiusThemeExtension(
        sm: AppBorderRadius.sm,
        md: AppBorderRadius.md,
        lg: AppBorderRadius.lg,
        xl: AppBorderRadius.xl,
        xxl: AppBorderRadius.xxl,
      );
}

double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}
