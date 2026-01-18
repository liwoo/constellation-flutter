import 'dart:math';
import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';

class ConnectionPainter extends CustomPainter {
  final List<Offset> points;
  final Size containerSize;
  final Offset? currentDragPosition; // For the trailing line to finger
  final bool isDragging;
  final double celebrationProgress; // 0.0-1.0 for celebration animation

  ConnectionPainter({
    required this.points,
    required this.containerSize,
    this.currentDragPosition,
    this.isDragging = false,
    this.celebrationProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Convert relative positions to actual positions
    final actualPoints = points.map((p) => Offset(
      p.dx * containerSize.width,
      p.dy * containerSize.height,
    )).toList();

    final isCelebrating = celebrationProgress > 0.0;

    if (isCelebrating) {
      _paintCelebration(canvas, actualPoints);
    } else {
      _paintNormal(canvas, actualPoints);
    }

    // Draw trailing line to current drag position (only when not celebrating)
    if (!isCelebrating && isDragging && currentDragPosition != null && actualPoints.isNotEmpty) {
      final lastPoint = actualPoints.last;
      final dragPoint = Offset(
        currentDragPosition!.dx * containerSize.width,
        currentDragPosition!.dy * containerSize.height,
      );

      final trailingPaint = Paint()
        ..color = AppColors.accentGold.withAlpha(150)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(lastPoint, dragPoint, trailingPaint);
    }
  }

  void _paintNormal(Canvas canvas, List<Offset> actualPoints) {
    final paint = Paint()
      ..color = AppColors.accentGold
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = AppColors.accentGold.withAlpha(80)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw connections
    if (actualPoints.length >= 2) {
      final path = Path();
      path.moveTo(actualPoints.first.dx, actualPoints.first.dy);
      for (int i = 1; i < actualPoints.length; i++) {
        path.lineTo(actualPoints[i].dx, actualPoints[i].dy);
      }
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    // Draw dots
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

  void _paintCelebration(Canvas canvas, List<Offset> actualPoints) {
    final t = celebrationProgress;
    final random = Random(42); // Fixed seed for consistent sparkles

    // === PHASE 1: Expanding rainbow rings from each point ===
    for (int i = 0; i < actualPoints.length; i++) {
      final point = actualPoints[i];
      // Stagger the ring animations
      final ringT = ((t * 2) - (i * 0.15)).clamp(0.0, 1.0);

      if (ringT > 0) {
        // Multiple expanding rings with rainbow colors
        for (int ring = 0; ring < 3; ring++) {
          final ringDelay = ring * 0.2;
          final adjustedT = ((ringT - ringDelay) * 1.5).clamp(0.0, 1.0);

          if (adjustedT > 0) {
            final radius = 20 + (adjustedT * 60);
            final alpha = ((1 - adjustedT) * 200).toInt().clamp(0, 255);

            // Rainbow hue based on point index and ring
            final hue = ((i * 60 + ring * 40 + t * 360) % 360);
            final color = HSLColor.fromAHSL(1.0, hue, 0.9, 0.6).toColor();

            final ringPaint = Paint()
              ..color = color.withAlpha(alpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 + (1 - adjustedT) * 4
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

            canvas.drawCircle(point, radius, ringPaint);
          }
        }
      }
    }

    // === PHASE 2: Electric path with traveling light ===
    if (actualPoints.length >= 2) {
      final path = Path();
      path.moveTo(actualPoints.first.dx, actualPoints.first.dy);
      for (int i = 1; i < actualPoints.length; i++) {
        path.lineTo(actualPoints[i].dx, actualPoints[i].dy);
      }

      // Outer glow - cycles through colors
      final glowHue = (t * 720) % 360;
      final glowColor = HSLColor.fromAHSL(1.0, glowHue, 0.8, 0.5).toColor();

      final outerGlowPaint = Paint()
        ..color = glowColor.withAlpha(100 + (sin(t * pi * 6) * 50).toInt())
        ..strokeWidth = 20 + sin(t * pi * 4) * 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawPath(path, outerGlowPaint);

      // Middle glow - white/gold pulse
      final middleGlowPaint = Paint()
        ..color = Color.lerp(AppColors.accentGold, Colors.white,
            (sin(t * pi * 8) + 1) / 2)!.withAlpha(180)
        ..strokeWidth = 12 + sin(t * pi * 6) * 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawPath(path, middleGlowPaint);

      // Core line - bright white
      final corePaint = Paint()
        ..color = Colors.white.withAlpha(220 + (sin(t * pi * 10) * 35).toInt())
        ..strokeWidth = 4 + sin(t * pi * 8) * 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, corePaint);

      // === Traveling light effect along the path ===
      _drawTravelingLight(canvas, actualPoints, t);
    }

    // === PHASE 3: Sparkle particles ===
    _drawSparkles(canvas, actualPoints, t, random);

    // === PHASE 4: Enhanced node points with starburst ===
    for (int i = 0; i < actualPoints.length; i++) {
      final point = actualPoints[i];
      final nodeT = ((t * 1.5) - (i * 0.1)).clamp(0.0, 1.0);

      // Starburst rays
      final rayCount = 8;
      for (int ray = 0; ray < rayCount; ray++) {
        final angle = (ray / rayCount) * pi * 2 + t * pi * 2;
        final rayLength = 15 + sin(t * pi * 4 + ray) * 10;
        final rayEnd = Offset(
          point.dx + cos(angle) * rayLength,
          point.dy + sin(angle) * rayLength,
        );

        final rayPaint = Paint()
          ..color = Colors.white.withAlpha((150 * (1 - nodeT * 0.5)).toInt())
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(point, rayEnd, rayPaint);
      }

      // Outer glow
      final glowPaint = Paint()
        ..color = AppColors.accentGold.withAlpha(150)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(point, 12 + sin(t * pi * 6) * 4, glowPaint);

      // Middle ring
      final ringPaint = Paint()
        ..color = Colors.white.withAlpha(200)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 8 + sin(t * pi * 8) * 2, ringPaint);

      // Core dot
      final coreDotPaint = Paint()
        ..color = AppColors.accentGold
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 5, coreDotPaint);
    }
  }

  void _drawTravelingLight(Canvas canvas, List<Offset> actualPoints, double t) {
    if (actualPoints.length < 2) return;

    // Calculate total path length
    double totalLength = 0;
    final segments = <double>[];
    for (int i = 1; i < actualPoints.length; i++) {
      final segLength = (actualPoints[i] - actualPoints[i - 1]).distance;
      segments.add(segLength);
      totalLength += segLength;
    }

    // Multiple traveling lights
    for (int lightIdx = 0; lightIdx < 3; lightIdx++) {
      // Position along path (0 to 1), offset for each light
      final lightT = ((t * 3) + lightIdx * 0.33) % 1.0;
      final targetDist = lightT * totalLength;

      // Find position on path
      double accumulated = 0;
      Offset? lightPos;

      for (int i = 0; i < segments.length; i++) {
        if (accumulated + segments[i] >= targetDist) {
          final segProgress = (targetDist - accumulated) / segments[i];
          lightPos = Offset.lerp(actualPoints[i], actualPoints[i + 1], segProgress);
          break;
        }
        accumulated += segments[i];
      }

      if (lightPos != null) {
        // Draw the traveling light with trail
        final trailLength = 5;
        for (int trail = 0; trail < trailLength; trail++) {
          final trailT = ((t * 3) + lightIdx * 0.33 - trail * 0.02) % 1.0;
          final trailDist = trailT * totalLength;

          double trailAccum = 0;
          Offset? trailPos;

          for (int i = 0; i < segments.length; i++) {
            if (trailAccum + segments[i] >= trailDist) {
              final segProgress = (trailDist - trailAccum) / segments[i];
              trailPos = Offset.lerp(actualPoints[i], actualPoints[i + 1], segProgress);
              break;
            }
            trailAccum += segments[i];
          }

          if (trailPos != null) {
            final trailAlpha = ((1 - trail / trailLength) * 200).toInt();
            final trailRadius = 6 - trail * 0.8;

            final trailPaint = Paint()
              ..color = Colors.white.withAlpha(trailAlpha)
              ..style = PaintingStyle.fill
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

            canvas.drawCircle(trailPos, trailRadius, trailPaint);
          }
        }
      }
    }
  }

  void _drawSparkles(Canvas canvas, List<Offset> actualPoints, double t, Random random) {
    // Generate sparkles around the path
    for (int i = 0; i < actualPoints.length; i++) {
      final point = actualPoints[i];

      // Each point emits sparkles
      for (int s = 0; s < 8; s++) {
        final sparkleT = ((t * 2) + s * 0.1 + i * 0.05) % 1.0;

        // Random direction but consistent per sparkle
        random.nextDouble(); // Advance random state
        final angle = (s / 8) * pi * 2 + random.nextDouble() * 0.5;
        final distance = sparkleT * 50 + 10;

        final sparklePos = Offset(
          point.dx + cos(angle) * distance,
          point.dy + sin(angle) * distance,
        );

        // Fade out as they travel
        final alpha = ((1 - sparkleT) * 255).toInt().clamp(0, 255);
        final sparkleSize = (1 - sparkleT) * 4 + 1;

        // Rainbow sparkles
        final hue = ((i * 40 + s * 30 + t * 360) % 360);
        final color = HSLColor.fromAHSL(1.0, hue, 0.9, 0.7).toColor();

        final sparklePaint = Paint()
          ..color = color.withAlpha(alpha)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(sparklePos, sparkleSize, sparklePaint);

        // Add a white core to some sparkles
        if (s % 2 == 0) {
          final corePaint = Paint()
            ..color = Colors.white.withAlpha((alpha * 0.8).toInt())
            ..style = PaintingStyle.fill;
          canvas.drawCircle(sparklePos, sparkleSize * 0.5, corePaint);
        }
      }
    }

    // Additional sparkles along the path segments
    for (int i = 1; i < actualPoints.length; i++) {
      final start = actualPoints[i - 1];
      final end = actualPoints[i];

      for (int s = 0; s < 5; s++) {
        final segT = (s + 1) / 6;
        final basePos = Offset.lerp(start, end, segT)!;

        final sparkleT = ((t * 3) + s * 0.15 + i * 0.1) % 1.0;
        final perpAngle = atan2(end.dy - start.dy, end.dx - start.dx) + pi / 2;
        final offset = sin(sparkleT * pi) * 20 * (random.nextDouble() > 0.5 ? 1 : -1);

        final sparklePos = Offset(
          basePos.dx + cos(perpAngle) * offset,
          basePos.dy + sin(perpAngle) * offset,
        );

        final alpha = (sin(sparkleT * pi) * 200).toInt().clamp(0, 255);

        final sparklePaint = Paint()
          ..color = Colors.white.withAlpha(alpha)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(sparklePos, 3, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) {
    return points != oldDelegate.points ||
        currentDragPosition != oldDelegate.currentDragPosition ||
        isDragging != oldDelegate.isDragging ||
        celebrationProgress != oldDelegate.celebrationProgress;
  }
}
