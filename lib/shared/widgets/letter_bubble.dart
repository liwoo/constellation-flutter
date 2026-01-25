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
    this.dwellProgress = 0.0,
    this.justConnected = false,
    this.onTap,
    this.size = AppConstants.letterBubbleSize,
  });

  final String letter;
  final int points;
  final bool isSelected;
  final bool isStartingLetter; // Highlight as the letter to start with
  final bool isHintLetter; // Highlight as part of hint word (animated)
  final bool isApproaching; // Hovering/dwelling over this letter
  final double dwellProgress; // 0.0-1.0 progress of dwell selection
  final bool justConnected; // Brief flash animation when connected
  final VoidCallback? onTap;
  final double size;

  @override
  State<LetterBubble> createState() => _LetterBubbleState();
}

class _LetterBubbleState extends State<LetterBubble>
    with TickerProviderStateMixin {
  late AnimationController _hintAnimController;
  late Animation<double> _hintPulse;
  late AnimationController _connectionFlashController;
  late Animation<double> _connectionFlash;
  late AnimationController _dwellProgressController;
  late Animation<double> _dwellProgress;

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

    // Connection flash animation - quick pulse when letter is connected
    _connectionFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _connectionFlash = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _connectionFlashController, curve: Curves.easeOut),
    );

    // Dwell progress animation - fills over the dwell duration
    _dwellProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: HitDetectionConfig.dwellTimeMs),
    );
    _dwellProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dwellProgressController, curve: Curves.linear),
    );

    if (widget.isHintLetter) {
      _hintAnimController.repeat(reverse: true);
    }
    if (widget.justConnected) {
      _connectionFlashController.forward(from: 0.0);
    }
    // Start dwell animation if approaching
    if (widget.isApproaching && !widget.isSelected) {
      _dwellProgressController.forward(from: 0.0);
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
    // Trigger connection flash when justConnected becomes true
    if (widget.justConnected && !oldWidget.justConnected) {
      _connectionFlashController.forward(from: 0.0);
    }
    // Handle dwell progress animation
    if (widget.isApproaching && !oldWidget.isApproaching && !widget.isSelected) {
      // Started approaching - begin dwell animation
      _dwellProgressController.forward(from: 0.0);
    } else if (!widget.isApproaching && oldWidget.isApproaching) {
      // Stopped approaching - reset dwell animation
      _dwellProgressController.reset();
    } else if (widget.isSelected && !oldWidget.isSelected) {
      // Got selected - reset dwell animation
      _dwellProgressController.reset();
    }
  }

  @override
  void dispose() {
    _hintAnimController.dispose();
    _connectionFlashController.dispose();
    _dwellProgressController.dispose();
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

          // Dwell progress indicator (circular arc around bubble)
          AnimatedBuilder(
            animation: _dwellProgressController,
            builder: (context, child) {
              final progress = _dwellProgress.value;
              if (progress <= 0 || progress >= 1.0 || widget.isSelected) {
                return const SizedBox.shrink();
              }
              return _buildDwellProgress(progress);
            },
          ),

          // Main letter bubble
          _buildBubble(),

          // Connection flash overlay
          AnimatedBuilder(
            animation: _connectionFlashController,
            builder: (context, child) {
              if (_connectionFlash.value <= 0) return const SizedBox.shrink();
              return _buildConnectionFlash(_connectionFlash.value);
            },
          ),

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

  /// Circular progress indicator showing dwell progress
  Widget _buildDwellProgress(double progress) {
    return Positioned(
      left: -6,
      top: -6,
      right: -6,
      bottom: -6,
      child: CustomPaint(
        painter: _DwellProgressPainter(
          progress: progress,
          color: AppColors.accentCyan,
          strokeWidth: 3.0,
        ),
      ),
    );
  }

  /// Flash effect when letter is successfully connected
  Widget _buildConnectionFlash(double progress) {
    // Fade out effect: full opacity at start, fading to transparent
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    // Expand effect: starts at bubble size, expands outward
    final expansion = 8.0 * progress;

    return Positioned(
      left: -expansion,
      top: -expansion,
      right: -expansion,
      bottom: -expansion,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentGold.withAlpha((opacity * 255).toInt()),
            width: 3.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withAlpha((opacity * 150).toInt()),
              blurRadius: 12 * progress,
              spreadRadius: 4 * progress,
            ),
          ],
        ),
      ),
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

/// Custom painter for circular dwell progress indicator
class _DwellProgressPainter extends CustomPainter {
  _DwellProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Background track (subtle)
    final trackPaint = Paint()
      ..color = color.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from top (-90 degrees) and sweep clockwise
    const startAngle = -3.14159 / 2; // -90 degrees in radians
    final sweepAngle = 2 * 3.14159 * progress; // Full circle * progress

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_DwellProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
