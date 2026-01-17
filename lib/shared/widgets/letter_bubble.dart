import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/badge_widget.dart';

/// White circular letter bubble with star-like glow and point badge
class LetterBubble extends StatefulWidget {
  const LetterBubble({
    super.key,
    required this.letter,
    required this.points,
    this.isSelected = false,
    this.isStartingLetter = false,
    this.isHintLetter = false,
    this.isApproaching = false,
    this.onTap,
    this.size = AppConstants.letterBubbleSize,
  });

  final String letter;
  final int points;
  final bool isSelected;
  final bool isStartingLetter; // Highlight as the letter to start with
  final bool isHintLetter; // Highlight as part of hint word (animated)
  final bool isApproaching; // Hovering/dwelling over this letter
  final VoidCallback? onTap;
  final double size;

  @override
  State<LetterBubble> createState() => _LetterBubbleState();
}

class _LetterBubbleState extends State<LetterBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _hintAnimController;
  late Animation<double> _hintPulse;

  @override
  void initState() {
    super.initState();
    _hintAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hintPulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _hintAnimController, curve: Curves.easeInOut),
    );

    if (widget.isHintLetter) {
      _hintAnimController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LetterBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHintLetter && !oldWidget.isHintLetter) {
      _hintAnimController.repeat(reverse: true);
    } else if (!widget.isHintLetter && oldWidget.isHintLetter) {
      _hintAnimController.stop();
      _hintAnimController.reset();
    }
  }

  @override
  void dispose() {
    _hintAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer glow effect (star-like)
          if (widget.isSelected) _buildSelectedGlow(),
          if (widget.isApproaching && !widget.isSelected) _buildApproachingGlow(),
          if (widget.isStartingLetter && !widget.isSelected && !widget.isApproaching) _buildStartingLetterGlow(),
          if (widget.isHintLetter) _buildHintGlow(),
          _buildStarGlow(),

          // Main letter bubble
          _buildBubble(),

          // Point badge
          Positioned(
            right: -4,
            top: -4,
            child: BadgeWidget(
              text: widget.points.toString(),
              size: AppConstants.badgeSizeSmall,
              backgroundColor: widget.isHintLetter
                  ? AppColors.accentOrange
                  : widget.isApproaching
                      ? AppColors.white
                      : widget.isStartingLetter
                          ? AppColors.accentCyan
                          : AppColors.accentGold,
              textColor: widget.isApproaching
                  ? AppColors.black
                  : widget.isStartingLetter
                      ? Colors.white
                      : AppColors.black,
            ),
          ),
        ],
      ),
    );

    // Wrap with scale animation if hint letter
    if (widget.isHintLetter) {
      return AnimatedBuilder(
        animation: _hintAnimController,
        builder: (context, child) {
          return Transform.scale(
            scale: _hintPulse.value,
            child: content,
          );
        },
      );
    }

    // Animate scale for approaching state
    return AnimatedScale(
      scale: widget.isApproaching ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: content,
    );
  }

  Widget _buildHintGlow() {
    return Positioned(
      left: -12,
      top: -12,
      right: -12,
      bottom: -12,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Bright orange inner glow
            BoxShadow(
              color: AppColors.accentOrange.withAlpha(220),
              blurRadius: 18,
              spreadRadius: 4,
            ),
            // Outer gold glow
            BoxShadow(
              color: AppColors.accentGold.withAlpha(150),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
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

  Widget _buildApproachingGlow() {
    return Positioned(
      left: -10,
      top: -10,
      right: -10,
      bottom: -10,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Bright white inner glow
            BoxShadow(
              color: Colors.white.withAlpha(230),
              blurRadius: 18,
              spreadRadius: 5,
            ),
            // Subtle cyan outer glow
            BoxShadow(
              color: AppColors.accentCyan.withAlpha(120),
              blurRadius: 25,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartingLetterGlow() {
    return Positioned(
      left: -10,
      top: -10,
      right: -10,
      bottom: -10,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Bright cyan inner glow
            BoxShadow(
              color: AppColors.accentCyan.withAlpha(200),
              blurRadius: 15,
              spreadRadius: 3,
            ),
            // Outer glow
            BoxShadow(
              color: AppColors.accentCyan.withAlpha(100),
              blurRadius: 25,
              spreadRadius: 5,
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
            // Soft white glow (star-like luminosity) - more subtle
            BoxShadow(
              color: Colors.white.withAlpha(widget.isSelected ? 120 : 60),
              blurRadius: widget.isSelected ? 12 : 8,
              spreadRadius: widget.isSelected ? 1 : 0,
            ),
            // Secondary softer glow - more subtle
            BoxShadow(
              color: Colors.white.withAlpha(widget.isSelected ? 50 : 25),
              blurRadius: widget.isSelected ? 20 : 14,
              spreadRadius: widget.isSelected ? 2 : 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble() {
    // Determine border based on state
    Border? border;
    if (widget.isHintLetter) {
      border = Border.all(color: AppColors.accentOrange, width: 3);
    } else if (widget.isSelected) {
      border = Border.all(color: AppColors.accentGold, width: 3);
    } else if (widget.isStartingLetter) {
      border = Border.all(color: AppColors.accentCyan, width: 3);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Selection/starting ring
        border: border,
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
              widget.letter.toUpperCase(),
              style: TextStyle(
                fontSize: widget.size * 0.4,
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
