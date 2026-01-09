import 'package:flutter/material.dart';

/// Purple to navy gradient background with glass shine effect
/// Matches the constellation-ui.jpeg reference exactly
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFAD1457), // Bright magenta/pink at top
            Color(0xFF880E4F), // Dark pink
            Color(0xFF6A1B9A), // Purple
            Color(0xFF4A148C), // Dark purple
            Color(0xFF311B92), // Deep purple
            Color(0xFF1A237E), // Indigo
            Color(0xFF0D1642), // Dark navy at bottom
          ],
          stops: [0.0, 0.15, 0.3, 0.45, 0.6, 0.8, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Glass shine effect - diagonal light reflection
          const Positioned.fill(
            child: GlassShineEffect(),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}

/// Glass shine effect widget - creates diagonal light reflection
class GlassShineEffect extends StatelessWidget {
  const GlassShineEffect({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlassShinePainter(),
      size: Size.infinite,
    );
  }
}

/// Custom painter for the diagonal glass shine effect
class _GlassShinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Main diagonal glass shine - prominent diagonal band
    _drawMainGlassShine(canvas, size);

    // Secondary subtle reflection
    _drawSecondaryShine(canvas, size);

    // Edge highlight at top
    _drawTopEdgeHighlight(canvas, size);
  }

  void _drawMainGlassShine(Canvas canvas, Size size) {
    // Create a prominent diagonal shine band from top-left to center-right
    final path = Path();

    // Start from top-left area
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.7, 0);
    // Diagonal down to center-right
    path.lineTo(size.width * 0.95, size.height * 0.35);
    path.lineTo(size.width * 0.6, size.height * 0.55);
    // Back to left side
    path.lineTo(0, size.height * 0.4);
    path.close();

    // Create gradient shader for the glass effect
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.6);
    final gradient = LinearGradient(
      begin: const Alignment(-1.0, -1.0),
      end: const Alignment(1.0, 1.0),
      colors: [
        Colors.white.withAlpha(0),
        Colors.white.withAlpha(18),
        Colors.white.withAlpha(35), // Peak brightness
        Colors.white.withAlpha(25),
        Colors.white.withAlpha(10),
        Colors.white.withAlpha(0),
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawSecondaryShine(Canvas canvas, Size size) {
    // Softer secondary shine to add depth
    final path = Path();
    path.moveTo(size.width * 0.2, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.45);
    path.lineTo(size.width * 0.3, size.height * 0.25);
    path.close();

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.5);
    final gradient = LinearGradient(
      begin: const Alignment(0.0, -1.0),
      end: const Alignment(0.5, 1.0),
      colors: [
        Colors.white.withAlpha(12),
        Colors.white.withAlpha(8),
        Colors.white.withAlpha(0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawTopEdgeHighlight(Canvas canvas, Size size) {
    // Subtle bright edge at the very top
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.08);
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x20FFFFFF), // Subtle white at top edge
        Color(0x00FFFFFF),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
