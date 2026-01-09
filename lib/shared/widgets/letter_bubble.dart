import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/badge_widget.dart';

/// White circular letter bubble with star-like glow and point badge
class LetterBubble extends StatelessWidget {
  const LetterBubble({
    super.key,
    required this.letter,
    required this.points,
    this.isSelected = false,
    this.onTap,
    this.size = AppConstants.letterBubbleSize,
  });

  final String letter;
  final int points;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer glow effect (star-like)
          if (isSelected) _buildSelectedGlow(),
          _buildStarGlow(),

          // Main letter bubble
          _buildBubble(),

          // Point badge
          Positioned(
            right: -4,
            top: -4,
            child: BadgeWidget(
              text: points.toString(),
              size: AppConstants.badgeSizeSmall,
              backgroundColor: AppColors.accentGold,
              textColor: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedGlow() {
    return Positioned(
      left: -8,
      top: -8,
      right: -8,
      bottom: -8,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withAlpha(150),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarGlow() {
    return Positioned(
      left: -4,
      top: -4,
      right: -4,
      bottom: -4,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Soft white glow (star-like luminosity)
            BoxShadow(
              color: Colors.white.withAlpha(isSelected ? 180 : 100),
              blurRadius: isSelected ? 15 : 10,
              spreadRadius: isSelected ? 2 : 1,
            ),
            // Secondary softer glow
            BoxShadow(
              color: Colors.white.withAlpha(isSelected ? 80 : 40),
              blurRadius: isSelected ? 25 : 18,
              spreadRadius: isSelected ? 4 : 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Selection ring
        border: isSelected
            ? Border.all(
                color: AppColors.accentGold,
                width: 3,
              )
            : null,
        // Drop shadow
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Main gradient - lighter at top (3D sphere effect)
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFF5F5F5),
              const Color(0xFFE8E8E8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Container(
          // Inner highlight (glass effect)
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 0.8,
              colors: [
                Colors.white.withAlpha(200),
                Colors.white.withAlpha(50),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              letter.toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                shadows: [
                  // Subtle text shadow for depth
                  Shadow(
                    color: Colors.black.withAlpha(30),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
