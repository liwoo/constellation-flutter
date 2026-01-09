import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Twinkling star dots decoration overlay
/// Creates a subtle animated starfield effect
class StarDecoration extends StatefulWidget {
  const StarDecoration({
    super.key,
    this.starCount = 80,
    this.starSize = 1.5,
  });

  final int starCount;
  final double starSize;

  @override
  State<StarDecoration> createState() => _StarDecorationState();
}

class _StarDecorationState extends State<StarDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _generateStars();
  }

  void _generateStars() {
    _stars = List.generate(widget.starCount, (index) {
      return _Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: widget.starSize * (0.3 + _random.nextDouble() * 0.7),
        baseOpacity: 0.2 + _random.nextDouble() * 0.5,
        twinkleSpeed: 0.5 + _random.nextDouble() * 2.0,
        twinkleOffset: _random.nextDouble() * math.pi * 2,
        hasBrightGlow: _random.nextDouble() > 0.85, // 15% chance of bright star
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _TwinklingStarPainter(
            stars: _stars,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double baseOpacity;
  final double twinkleSpeed;
  final double twinkleOffset;
  final bool hasBrightGlow;

  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseOpacity,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.hasBrightGlow,
  });

  double getOpacity(double animationValue) {
    // Create smooth twinkling using sine wave
    final twinkle = math.sin(
      (animationValue * twinkleSpeed * math.pi * 2) + twinkleOffset,
    );
    // Map from -1..1 to a subtle opacity variation
    final variation = twinkle * 0.3;
    return (baseOpacity + variation).clamp(0.1, 1.0);
  }
}

class _TwinklingStarPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;

  _TwinklingStarPainter({
    required this.stars,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final x = star.x * size.width;
      final y = star.y * size.height;
      final opacity = star.getOpacity(animationValue);

      // Main star dot
      final paint = Paint()
        ..color = Colors.white.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), star.size, paint);

      // Bright stars get a soft glow
      if (star.hasBrightGlow && opacity > 0.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withAlpha((opacity * 80).round())
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 2);

        canvas.drawCircle(Offset(x, y), star.size * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_TwinklingStarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
