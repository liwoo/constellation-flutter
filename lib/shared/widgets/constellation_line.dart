import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Draws constellation connection lines between points
class ConstellationLine extends StatelessWidget {
  const ConstellationLine({
    super.key,
    required this.points,
    this.color = AppColors.accentGold,
    this.strokeWidth = 2.0,
  });

  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: LinePainter(
        points: points,
        color: color,
        strokeWidth: strokeWidth,
      ),
      size: .infinite,
    );
  }
}

class LinePainter extends CustomPainter {
  LinePainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = .round
      ..style = .stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw dots at connection points
    final dotPaint = Paint()
      ..color = color
      ..style = .fill;

    for (final point in points) {
      canvas.drawCircle(point, strokeWidth * 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
