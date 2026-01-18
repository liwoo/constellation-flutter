import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// White mystery orb matching the constellation style with "?" symbol
/// Activates on dwell (like letters) and gives random rewards/penalties
class MysteryOrbWidget extends StatefulWidget {
  const MysteryOrbWidget({
    super.key,
    required this.size,
    this.isActive = true,
    this.isApproaching = false,
    this.dwellProgress = 0.0, // 0.0 to 1.0 for dwell indicator
  });

  final double size;
  final bool isActive; // Whether the orb is visible
  final bool isApproaching; // Hovering over the orb
  final double dwellProgress; // Progress of dwell time (0-1)

  @override
  State<MysteryOrbWidget> createState() => _MysteryOrbWidgetState();
}

class _MysteryOrbWidgetState extends State<MysteryOrbWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  // Mystery orb colors - white like constellation letters with purple accent
  static const Color _purpleAccent = Color(0xFF9C27B0); // Purple for "?"

  @override
  void initState() {
    super.initState();

    // Shimmer animation - continuous subtle sparkle
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _shimmerController.repeat();

    // Pulse animation for approaching state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isApproaching) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MysteryOrbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isApproaching && !oldWidget.isApproaching) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isApproaching && oldWidget.isApproaching) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    Widget content = AnimatedBuilder(
      animation: Listenable.merge([_shimmerAnimation, _pulseAnimation]),
      builder: (context, child) {
        final scale = widget.isApproaching ? _pulseAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Outer glow effect
              _buildGlow(),

              // Dwell progress indicator
              if (widget.dwellProgress > 0) _buildDwellIndicator(),

              // Main orb
              _buildOrb(),

              // Shimmer overlay
              _buildShimmer(),
            ],
          ),
        );
      },
    );

    // Fade in animation when appearing
    return AnimatedOpacity(
      opacity: widget.isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: content,
    );
  }

  Widget _buildGlow() {
    final glowIntensity = widget.isApproaching ? 1.5 : 1.0;

    return Positioned(
      left: -4,
      top: -4,
      right: -4,
      bottom: -4,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Soft white glow (star-like luminosity) - matches letter bubbles
            BoxShadow(
              color: Colors.white.withAlpha((80 * glowIntensity).round()),
              blurRadius: 10 * glowIntensity,
              spreadRadius: 1 * glowIntensity,
            ),
            // Secondary softer glow
            BoxShadow(
              color: Colors.white.withAlpha((40 * glowIntensity).round()),
              blurRadius: 18 * glowIntensity,
              spreadRadius: 2 * glowIntensity,
            ),
            // Purple accent glow for mystery effect
            if (widget.isApproaching)
              BoxShadow(
                color: _purpleAccent.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 5,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDwellIndicator() {
    return Positioned(
      left: -4,
      top: -4,
      right: -4,
      bottom: -4,
      child: CustomPaint(
        painter: _DwellProgressPainter(
          progress: widget.dwellProgress,
          color: _purpleAccent, // Purple progress ring
        ),
      ),
    );
  }

  Widget _buildOrb() {
    // Determine border based on approaching state
    Border? border;
    if (widget.isApproaching) {
      border = Border.all(color: _purpleAccent, width: 3);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
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
          // Main gradient - white like letter bubbles (3D sphere effect)
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
          // Inner highlight (glass effect) - same as letter bubbles
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
              '?',
              style: TextStyle(
                fontSize: widget.size * 0.5,
                fontWeight: FontWeight.bold,
                color: _purpleAccent, // Purple "?" to indicate mystery
                shadows: [
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

  Widget _buildShimmer() {
    final shimmerValue = _shimmerAnimation.value;

    return Positioned.fill(
      child: ClipOval(
        child: CustomPaint(
          painter: _ShimmerPainter(
            shimmerPosition: shimmerValue,
            color: _purpleAccent, // Subtle purple shimmer for mystery effect
          ),
        ),
      ),
    );
  }
}

/// Painter for the dwell progress ring
class _DwellProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _DwellProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw arc from top, clockwise
    const startAngle = -3.14159 / 2; // Start from top
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_DwellProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Painter for the shimmer effect
class _ShimmerPainter extends CustomPainter {
  final double shimmerPosition;
  final Color color;

  _ShimmerPainter({
    required this.shimmerPosition,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Calculate shimmer position moving diagonally
    final shimmerX = size.width * (shimmerPosition - 0.2);
    final shimmerY = size.height * (shimmerPosition - 0.2);

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (shimmerX / size.width) * 2 - 1,
          (shimmerY / size.height) * 2 - 1,
        ),
        radius: 0.4,
        colors: [
          color.withAlpha(100),
          color.withAlpha(30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width));

    canvas.drawCircle(center, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) {
    return oldDelegate.shimmerPosition != shimmerPosition;
  }
}
