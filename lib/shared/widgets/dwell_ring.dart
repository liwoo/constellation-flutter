import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';

/// Rebuilds with the 0-1 progress of a star dwell that began at
/// [dwellStartTime], filling over the same time the game takes to click a
/// star in. Picks up mid-way if the dwell started before this was built.
class DwellProgress extends StatefulWidget {
  const DwellProgress({
    super.key,
    required this.dwellStartTime,
    required this.builder,
  });

  final DateTime? dwellStartTime;
  final Widget Function(BuildContext context, double progress) builder;

  @override
  State<DwellProgress> createState() => _DwellProgressState();
}

class _DwellProgressState extends State<DwellProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: HitDetectionConfig.dwellTimeMs),
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final start = widget.dwellStartTime;
    final from = start == null
        ? 0.0
        : (DateTime.now().difference(start).inMilliseconds / HitDetectionConfig.dwellTimeMs)
            .clamp(0.0, 1.0);
    _controller.forward(from: from);
  }

  @override
  void didUpdateWidget(DwellProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dwellStartTime != oldWidget.dwellStartTime) _start();
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
      builder: (context, _) => widget.builder(context, _controller.value),
    );
  }
}

/// Circular dwell ring: a faint track with an arc sweeping clockwise from
/// the top as [progress] goes 0 to 1
class DwellRingPainter extends CustomPainter {
  DwellRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3.0,
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
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc, from the top, clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(DwellRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
