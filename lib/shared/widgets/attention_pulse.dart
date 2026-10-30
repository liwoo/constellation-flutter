import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Gently breathes its child with a soft halo to draw the eye
/// (e.g. the hint button when the player looks stuck).
class AttentionPulse extends StatefulWidget {
  const AttentionPulse({
    super.key,
    required this.active,
    required this.child,
    this.color = AppColors.accentCyan,
  });

  final bool active;
  final Widget child;
  final Color color;

  @override
  State<AttentionPulse> createState() => _AttentionPulseState();
}

class _AttentionPulseState extends State<AttentionPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AttentionPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.animateTo(0, duration: const Duration(milliseconds: 250));
    }
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
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        if (t == 0) return child!;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withAlpha((170 * t).round()),
                      blurRadius: 14 + 12 * t,
                      spreadRadius: 2 + 6 * t,
                    ),
                  ],
                ),
              ),
            ),
            Transform.scale(scale: 1 + 0.09 * t, child: child),
          ],
        );
      },
    );
  }
}
