import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Action bubble for GO (submit), DEL (delete), and bonus actions (space, x2)
/// Styled differently from letter bubbles to stand out
class ActionBubble extends StatelessWidget {
  const ActionBubble({
    super.key,
    required this.label,
    required this.isSubmit,
    this.isBonus = false,
    this.isHint = false,
    this.isStar = false,
    this.isActive = false,
    this.onTap,
    this.size = AppConstants.letterBubbleSize,
    this.badgeCount = 0, // Shows count badge if > 0
  });

  final String label;
  final bool isSubmit; // true = GO (green), false = DEL (red) or bonus
  final bool isBonus; // true = bonus button (gold/orange)
  final bool isHint; // true = hint button (cyan/purple)
  final bool isStar; // true = star currency button (purple/gold)
  final bool isActive;
  final VoidCallback? onTap;
  final double size;
  final int badgeCount; // Shows usage count badge

  @override
  Widget build(BuildContext context) {
    // Use greyed out colors when inactive
    Color activeColor;
    if (isStar) {
      activeColor = const Color(0xFF9C27B0); // Purple for star buttons
    } else if (isHint) {
      activeColor = AppColors.accentCyan; // Cyan for hint button
    } else if (isBonus) {
      activeColor = AppColors.accentGold; // Gold for bonus buttons
    } else if (isSubmit) {
      activeColor = const Color(0xFF4CAF50); // Green for GO
    } else {
      activeColor = const Color(0xFFE91E63); // Pink/Red for DEL
    }

    final Color baseColor = isActive
        ? activeColor
        : Colors.grey.shade600; // Grey when disabled

    final HSLColor hsl = HSLColor.fromColor(baseColor);
    final Color lighterColor = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final Color darkerColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Outer glow (only when active)
            if (isActive) _buildGlow(activeColor),

            // Main bubble
            _buildBubble(baseColor, lighterColor, darkerColor),

            // Badge count (for bonus buttons)
            if (badgeCount > 0) _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    // Star buttons show cost with star icon
    if (isStar) {
      return Positioned(
        right: -6,
        top: -6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accentGold,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withAlpha(100),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.star,
                color: Colors.black,
                size: 10,
              ),
            ],
          ),
        ),
      );
    }

    // Regular bonus badge shows usage count
    return Positioned(
      right: -4,
      top: -4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.accentOrange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withAlpha(100),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          minHeight: 18,
        ),
        child: Center(
          child: Text(
            '+$badgeCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlow(Color baseColor) {
    return Positioned(
      left: -6,
      top: -6,
      right: -6,
      bottom: -6,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: baseColor.withAlpha(isActive ? 200 : 120),
              blurRadius: isActive ? 20 : 12,
              spreadRadius: isActive ? 4 : 2,
            ),
            BoxShadow(
              color: Colors.white.withAlpha(isActive ? 100 : 60),
              blurRadius: isActive ? 15 : 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(Color baseColor, Color lighterColor, Color darkerColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: Colors.white, width: 3)
            : Border.all(color: darkerColor.withAlpha(150), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              lighterColor,
              baseColor,
              darkerColor,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Container(
          // Inner highlight
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 0.8,
              colors: [
                Colors.white.withAlpha(100),
                Colors.white.withAlpha(30),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
                shadows: [
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
    );
  }
}
