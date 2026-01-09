import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Circular badge widget with 3D gradient effect
/// Used for displaying points, timer, counts, etc.
class BadgeWidget extends StatelessWidget {
  const BadgeWidget({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.accentGold,
    this.textColor = AppColors.black,
    this.icon,
    this.size = AppConstants.badgeSizeMedium,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Create lighter and darker versions for 3D effect
    final HSLColor hsl = HSLColor.fromColor(backgroundColor);
    final Color lighterColor = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final Color darkerColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    final Color darkestColor = hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Outer shadow for depth
        boxShadow: [
          // Bottom shadow
          BoxShadow(
            color: darkestColor.withAlpha(180),
            blurRadius: 1,
            offset: const Offset(0, 2),
          ),
          // Ambient shadow
          BoxShadow(
            color: AppColors.black.withAlpha(60),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Main gradient - lighter at top, darker at bottom
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lighterColor,
              backgroundColor,
              darkerColor,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
          // Inner border for 3D effect
          border: Border.all(
            color: darkestColor.withAlpha(100),
            width: 1,
          ),
        ),
        child: Container(
          // Inner highlight overlay
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(80),
                Colors.white.withAlpha(20),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    color: textColor,
                    size: size * 0.5,
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.white.withAlpha(150),
                          offset: const Offset(0, -0.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}
