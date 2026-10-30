import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Comet for a shooting star: while [streak] runs 0-1 the head flies from
/// [from] to [to] trailing a long golden tail and sparkles; once landed a
/// short tail stays pointing back the way it came, shimmering with [glow].
class ShootingStarPainter extends CustomPainter {
  ShootingStarPainter({
    required this.from,
    required this.to,
    required this.streak,
    required this.glow,
    required this.starSize,
    this.opacity = 1.0,
  });

  final Offset from; // Pixels
  final Offset to; // Pixels
  final double streak; // 0-1 flight progress
  final double glow; // 0-1, repeating
  final double starSize;
  final double opacity;

  static const _gold = AppColors.accentGold;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final travel = to - from;
    if (travel.distance < 1) return;
    final back = -travel / travel.distance; // Unit vector toward where it came from

    if (streak < 1) {
      _paintFlight(canvas, back);
    } else {
      _paintResting(canvas, back);
    }
  }

  void _paintFlight(Canvas canvas, Offset back) {
    final t = Curves.easeOutCubic.transform(streak);
    final head = Offset.lerp(from, to, t)!;
    final tailLength = starSize * (4.5 - 2.5 * t);
    _tail(canvas, head, head + back * tailLength, width: 5, alpha: 1.0);

    // Sparkles shed along the tail
    final perp = Offset(-back.dy, back.dx);
    for (var i = 0; i < 10; i++) {
      final along = (i + 1) / 11;
      final wobble = sin(i * 2.7 + streak * 12) * starSize * 0.18;
      final p = head + back * (tailLength * along) + perp * wobble;
      final a = (1 - along) * (0.6 + 0.4 * sin(i * 1.3 + streak * 20).abs());
      canvas.drawCircle(
        p,
        1.2 + (1 - along) * 1.8,
        Paint()..color = Colors.white.withValues(alpha: a * opacity),
      );
    }

    // Blazing head
    canvas.drawCircle(
      head,
      starSize * 0.3,
      Paint()
        ..color = _gold.withValues(alpha: 0.8 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(head, 5, Paint()..color = Colors.white.withValues(alpha: opacity));

    // Landing burst
    if (streak > 0.8) {
      final b = (streak - 0.8) / 0.2;
      canvas.drawCircle(
        to,
        starSize * (0.5 + 0.8 * b),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - b) + 0.5
          ..color = _gold.withValues(alpha: (1 - b) * opacity),
      );
    }
  }

  void _paintResting(Canvas canvas, Offset back) {
    final pulse = 0.5 + 0.5 * sin(glow * 2 * pi);
    final start = to + back * (starSize * 0.45);
    _tail(canvas, start, start + back * (starSize * (1.3 + 0.2 * pulse)), width: 4 + pulse * 2, alpha: 0.7);

    // Halo behind the bubble
    canvas.drawCircle(
      to,
      starSize * (0.62 + 0.06 * pulse),
      Paint()
        ..color = _gold.withValues(alpha: (0.35 + 0.25 * pulse) * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Three twinkles orbiting
    for (var i = 0; i < 3; i++) {
      final angle = glow * 2 * pi + i * 2 * pi / 3;
      final p = to + Offset(cos(angle), sin(angle)) * (starSize * 0.68);
      final a = 0.5 + 0.5 * sin(glow * 4 * pi + i * 2);
      _twinkle(canvas, p, 2.5 + a * 1.5, a);
    }
  }

  /// Golden tail fading out from [head] to [end]
  void _tail(Canvas canvas, Offset head, Offset end, {required double width, required double alpha}) {
    final shader = LinearGradient(
      colors: [
        _gold.withValues(alpha: alpha * opacity),
        AppColors.accentOrange.withValues(alpha: alpha * 0.4 * opacity),
        Colors.transparent,
      ],
      stops: const [0, 0.45, 1],
      transform: _GradientAlong(head, end),
    ).createShader(Rect.fromLTWH(0, 0, (end - head).distance, 1));
    final paint = Paint()
      ..shader = shader
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      head,
      end,
      paint
        ..strokeWidth = width * 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawLine(
      head,
      end,
      paint
        ..strokeWidth = width
        ..maskFilter = null,
    );
  }

  void _twinkle(Canvas canvas, Offset c, double r, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * opacity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), paint);
    canvas.drawLine(c - Offset(0, r), c + Offset(0, r), paint);
    canvas.drawCircle(c, 1.2, paint);
  }

  @override
  bool shouldRepaint(ShootingStarPainter old) =>
      old.from != from ||
      old.to != to ||
      old.streak != streak ||
      old.glow != glow ||
      old.starSize != starSize ||
      old.opacity != opacity;
}

/// Rotates/translates a gradient laid out along +x so it runs from
/// [head] to [end]
class _GradientAlong extends GradientTransform {
  const _GradientAlong(this.head, this.end);

  final Offset head;
  final Offset end;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final d = end - head;
    return Matrix4.identity()
      ..translateByDouble(head.dx, head.dy, 0, 1)
      ..rotateZ(atan2(d.dy, d.dx));
  }
}

/// Pops a short message over the board when [trigger] changes to a new
/// non-null value, then fades it away. Ignores the value going back to null
/// so the message always finishes.
class ShootingStarCallout extends StatefulWidget {
  const ShootingStarCallout({
    super.key,
    required this.trigger,
    required this.title,
    this.subtitle,
    this.duration = const Duration(milliseconds: 2400),
  });

  final Object? trigger;
  final String title;
  final String? subtitle;
  final Duration duration;

  @override
  State<ShootingStarCallout> createState() => _ShootingStarCalloutState();
}

class _ShootingStarCalloutState extends State<ShootingStarCallout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  String _title = '';
  String? _subtitle;

  @override
  void initState() {
    super.initState();
    if (widget.trigger != null) _show();
  }

  @override
  void didUpdateWidget(ShootingStarCallout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) _show();
  }

  void _show() {
    _title = widget.title;
    _subtitle = widget.subtitle;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          if (!_controller.isAnimating || t == 0) return const SizedBox.shrink();
          final opacity = t < 0.12 ? t / 0.12 : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
          final scale = t < 0.12 ? 0.6 + 0.5 * Curves.easeOutBack.transform(t / 0.12) : 1.1 - 0.1 * min(1.0, (t - 0.12) * 5);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryDarkPurple.withAlpha(215),
                AppColors.primaryPurple.withAlpha(215),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withAlpha(120),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _title,
                    style: GoogleFonts.orbitron(
                      color: AppColors.accentGold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              if (_subtitle != null)
                Text(
                  _subtitle!,
                  style: GoogleFonts.exo2(
                    color: Colors.white.withAlpha(220),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
