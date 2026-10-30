import 'dart:math';

import 'package:flutter/material.dart';
import 'package:constellation_app/shared/widgets/star_decoration.dart';

/// On wide screens (laptops, tablets, desktop web) the app runs inside a
/// centered phone-sized frame, so layout, star spacing and gestures are
/// exactly what players get on mobile.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child});

  final Widget child;

  /// Screens wider than this get the frame
  static const double breakpoint = 600;

  static const double _maxWidth = 430;
  static const double _minWidth = 360;
  static const double _maxHeight = 932;

  /// Phone-like width:height
  static const double _aspect = 0.5;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    if (screen.width <= breakpoint) return child;

    // Float the frame with a margin when there's room, else fill the height
    final margin = screen.height > 720 ? 24.0 : 0.0;
    final height = min(screen.height - margin * 2, _maxHeight);
    final width = min((height * _aspect).clamp(_minWidth, _maxWidth), screen.width);
    final radius = margin > 0 ? 36.0 : 0.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 1.2,
          colors: [Color(0xFF2A1458), Color(0xFF0D0A24), Color(0xFF05040F)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: StarDecoration(starCount: 140, starSize: 1.6),
          ),
          Center(
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: margin > 0
                    ? Border.all(color: Colors.white.withAlpha(40), width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAD1457).withAlpha(70),
                    blurRadius: 60,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                // Everything inside sizes itself to the phone, not the monitor
                child: MediaQuery(
                  data: media.copyWith(
                    size: Size(width, height),
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                    viewInsets: EdgeInsets.zero,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
