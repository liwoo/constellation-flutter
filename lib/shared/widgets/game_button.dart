import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Styled game button with gradient and 3D effect
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;

    // Colors based on primary/secondary and enabled state
    final Color baseColor = widget.isPrimary
        ? AppColors.accentGold
        : AppColors.primaryPurple;

    final HSLColor hsl = HSLColor.fromColor(baseColor);
    final Color lighterColor = hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
    final Color darkerColor = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    final Color darkestColor = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    final Color textColor = widget.isPrimary ? AppColors.black : AppColors.white;

    // Opacity for disabled state
    final double opacity = isEnabled ? 1.0 : 0.5;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: Opacity(
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              // Outer shadow - reduced when pressed
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: darkestColor.withAlpha(150),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : [
                      // Bottom edge shadow (3D depth)
                      BoxShadow(
                        color: darkestColor,
                        blurRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                      // Soft ambient shadow
                      BoxShadow(
                        color: AppColors.black.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                // Main gradient
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lighterColor,
                    baseColor,
                    darkerColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                // Subtle border
                border: Border.all(
                  color: darkestColor.withAlpha(80),
                  width: 1,
                ),
              ),
              child: Container(
                // Inner highlight
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg - 1),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withAlpha(_isPressed ? 20 : 60),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    shadows: widget.isPrimary
                        ? null
                        : [
                            Shadow(
                              color: AppColors.black.withAlpha(100),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
