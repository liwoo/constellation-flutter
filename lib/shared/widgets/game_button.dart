import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Styled game button with gradient and 3D effect
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double? width;

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
    final Color lighterColor =
        hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final Color darkerColor =
        hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    final Color darkestColor =
        hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();

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
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
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
            border: Border.all(
              color: darkestColor.withAlpha(120),
              width: 1.5,
            ),
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
                      color: AppColors.black.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg - 1),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              // Inner highlight overlay
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.white.withAlpha(_isPressed ? 30 : 80),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: widget.isPrimary
                      ? [
                          Shadow(
                            color: Colors.white.withAlpha(100),
                            offset: const Offset(0, 1),
                            blurRadius: 0,
                          ),
                        ]
                      : [
                          Shadow(
                            color: AppColors.black.withAlpha(150),
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
    );
  }
}
