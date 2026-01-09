import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';

class ConnectionPainter extends CustomPainter {
  final List<Offset> points;
  final Size containerSize;
  final Offset? currentDragPosition; // For the trailing line to finger
  final bool isDragging;

  ConnectionPainter({
    required this.points,
    required this.containerSize,
    this.currentDragPosition,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.accentGold
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Convert relative positions to actual positions
    final actualPoints = points.map((p) => Offset(
      p.dx * containerSize.width,
      p.dy * containerSize.height,
    )).toList();

    // Draw glow effect
    final glowPaint = Paint()
      ..color = AppColors.accentGold.withAlpha(80)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw connections between selected letters
    if (actualPoints.length >= 2) {
      final path = Path();
      path.moveTo(actualPoints.first.dx, actualPoints.first.dy);

      for (int i = 1; i < actualPoints.length; i++) {
        path.lineTo(actualPoints[i].dx, actualPoints[i].dy);
      }

      // Draw glow first
      canvas.drawPath(path, glowPaint);
      // Draw main line
      canvas.drawPath(path, paint);
    }

    // Draw trailing line to current drag position
    if (isDragging && currentDragPosition != null && actualPoints.isNotEmpty) {
      final lastPoint = actualPoints.last;
      final dragPoint = Offset(
        currentDragPosition!.dx * containerSize.width,
        currentDragPosition!.dy * containerSize.height,
      );

      // Dashed/faded line to current position
      final trailingPaint = Paint()
        ..color = AppColors.accentGold.withAlpha(150)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(lastPoint, dragPoint, trailingPaint);
    }

    // Draw dots at connection points
    final dotPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = AppColors.accentGold.withAlpha(100)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final point in actualPoints) {
      canvas.drawCircle(point, 8, dotGlowPaint);
      canvas.drawCircle(point, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return points != oldDelegate.points ||
        currentDragPosition != oldDelegate.currentDragPosition ||
        isDragging != oldDelegate.isDragging;
  }
}
