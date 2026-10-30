import 'dart:math';

import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Where the round-start shimmer is at a given moment
class ShimmerFrame {
  const ShimmerFrame({
    required this.path,
    required this.localMs,
  });

  /// Star ids of the word being traced
  final List<int> path;

  /// Milliseconds into this word's shimmer
  final double localMs;

  /// Locate [elapsedMs] on the timeline of [paths]; null between words
  /// or once everything has faded
  static ShimmerFrame? at(List<List<int>> paths, double elapsedMs) {
    var start = 0.0;
    for (final path in paths) {
      final length = WordPreviewConfig.wordMs(path.length);
      if (elapsedMs < start) return null; // In the gap before this word
      if (elapsedMs < start + length) {
        return ShimmerFrame(path: path, localMs: elapsedMs - start);
      }
      start += length + WordPreviewConfig.gapMs;
    }
    return null;
  }

  /// Index of the star the sweep has most recently reached
  int get headIndex => min(
        (localMs / WordPreviewConfig.starStepMs).floor(),
        path.length - 1,
      );

  /// Whole word fades out after the hold
  double get fade {
    final fadeStart = path.length * WordPreviewConfig.starStepMs + WordPreviewConfig.holdMs;
    if (localMs <= fadeStart) return 1;
    return (1 - (localMs - fadeStart) / WordPreviewConfig.fadeMs).clamp(0.0, 1.0);
  }

  /// 0-1 brightness of the [index]th star (lights as the sweep reaches it)
  double brightness(int index) {
    final lit = ((localMs - index * WordPreviewConfig.starStepMs) /
            WordPreviewConfig.starStepMs)
        .clamp(0.0, 1.0);
    return Curves.easeOut.transform(lit) * fade;
  }

  /// Extra flare on a star just as the sweep arrives
  double twinkle(int index) {
    final sinceArrival = localMs - index * WordPreviewConfig.starStepMs;
    if (sinceArrival < 0) return 0;
    return (1 - sinceArrival / (WordPreviewConfig.starStepMs * 2.5)).clamp(0.0, 1.0) * fade;
  }
}

/// Paints the shimmer of one word across the stars. Drawn twice: [front]
/// false for the halo + trace behind the stars, true for the rings and
/// sparkles over them (so letters stay readable).
class StarShimmerPainter extends CustomPainter {
  StarShimmerPainter({
    required this.frame,
    required this.centers,
    required this.starSize,
    required this.front,
  });

  final ShimmerFrame? frame;

  /// Star id -> centre in pixels
  final Map<int, Offset> centers;
  final double starSize;
  final bool front;

  static const _gold = AppColors.accentGold;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = this.frame;
    if (frame == null) return;
    final points = [for (final id in frame.path) centers[id]];
    if (points.any((p) => p == null)) return;
    final stars = points.cast<Offset>();

    front ? _paintFront(canvas, frame, stars) : _paintBehind(canvas, frame, stars);
  }

  void _paintBehind(Canvas canvas, ShimmerFrame frame, List<Offset> stars) {
    // Trace line, growing towards the star the sweep is heading for
    final head = frame.headIndex;
    final progressToNext =
        (frame.localMs / WordPreviewConfig.starStepMs - head).clamp(0.0, 1.0);
    final trace = Path()..moveTo(stars.first.dx, stars.first.dy);
    for (var i = 1; i <= head; i++) {
      trace.lineTo(stars[i].dx, stars[i].dy);
    }
    if (head + 1 < stars.length) {
      final tip = Offset.lerp(stars[head], stars[head + 1], progressToNext)!;
      trace.lineTo(tip.dx, tip.dy);
    }
    canvas.drawPath(
      trace,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3
        ..color = _gold.withAlpha((170 * frame.fade).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // Warm halo behind each lit star
    final radius = starSize * 0.9;
    for (var i = 0; i < stars.length; i++) {
      final b = frame.brightness(i);
      if (b <= 0) continue;
      canvas.drawCircle(
        stars[i],
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _gold.withAlpha((210 * b).round()),
              _gold.withAlpha(0),
            ],
          ).createShader(Rect.fromCircle(center: stars[i], radius: radius)),
      );
    }
  }

  void _paintFront(Canvas canvas, ShimmerFrame frame, List<Offset> stars) {
    final ringRadius = starSize / 2 + 2;
    for (var i = 0; i < stars.length; i++) {
      final b = frame.brightness(i);
      if (b <= 0) continue;
      final center = stars[i];

      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Color.lerp(_gold, Colors.white, frame.twinkle(i))!
              .withAlpha((235 * b).round()),
      );

      // Four-point sparkle on the rim as the sweep lands
      final t = frame.twinkle(i);
      if (t > 0) {
        _sparkle(
          canvas,
          center + Offset(-ringRadius * 0.7, -ringRadius * 0.7),
          starSize * 0.32 * (0.5 + t),
          t,
        );
      }
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, double alpha) {
    final w = r * 0.22;
    final star = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(
      star,
      Paint()..color = Colors.white.withAlpha((255 * alpha).round()),
    );
    canvas.drawCircle(
      c,
      r * 0.6,
      Paint()
        ..color = _gold.withAlpha((120 * alpha).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(StarShimmerPainter old) =>
      old.frame?.localMs != frame?.localMs ||
      old.frame?.path != frame?.path ||
      old.starSize != starSize;
}
