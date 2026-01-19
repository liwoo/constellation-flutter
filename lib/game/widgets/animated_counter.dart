import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/shared/services/haptic_service.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Animated counter that counts up with haptic feedback
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.label,
    required this.endValue,
    this.startValue = 0,
    this.suffix = '',
    this.prefix = '',
    this.duration = const Duration(milliseconds: 1000),
    this.delay = Duration.zero,
    this.isHighlighted = false,
    this.hapticInterval = 5,
    this.onComplete,
  });

  final String label;
  final int endValue;
  final int startValue;
  final String suffix;
  final String prefix;
  final Duration duration;
  final Duration delay;
  final bool isHighlighted;
  final int hapticInterval; // Haptic every N increments
  final VoidCallback? onComplete;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _lastHapticValue = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: widget.startValue.toDouble(),
      end: widget.endValue.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _lastHapticValue = widget.startValue;

    _animation.addListener(_onAnimationUpdate);
    _controller.addStatusListener(_onAnimationStatus);

    // Start after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _started = true);
        _controller.forward();
      }
    });
  }

  void _onAnimationUpdate() {
    final currentValue = _animation.value.round();
    final delta = (currentValue - _lastHapticValue).abs();

    // Trigger haptic at intervals
    if (delta >= widget.hapticInterval) {
      HapticService.instance.light();
      _lastHapticValue = currentValue;
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Final haptic on completion
      HapticService.instance.medium();
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _animation.removeListener(_onAnimationUpdate);
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _started ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final value = _animation.value.round();
          final displayValue = '${widget.prefix}$value${widget.suffix}';

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(180),
                  fontSize: 14,
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.0),
                duration: const Duration(milliseconds: 100),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: _controller.isAnimating ? 1.0 + (_controller.velocity.abs() * 0.001).clamp(0, 0.1) : 1.0,
                    child: Text(
                      displayValue,
                      style: GoogleFonts.orbitron(
                        color: widget.isHighlighted
                            ? AppColors.accentGold
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Celebration stats panel with staggered animated counters
class CelebrationStatsPanel extends StatelessWidget {
  const CelebrationStatsPanel({
    super.key,
    required this.score,
    required this.lettersCompleted,
    required this.timeRemaining,
    required this.pointsEarned,
  });

  final int score;
  final int lettersCompleted;
  final int timeRemaining;
  final int pointsEarned;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkPurple.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGold.withAlpha(100),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Letters Done - quick count
          AnimatedCounter(
            label: 'Letters Done',
            endValue: lettersCompleted,
            suffix: ' / 25',
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
            hapticInterval: 1,
          ),
          const SizedBox(height: 12),

          // Round Score - points earned this round (highlighted)
          AnimatedCounter(
            label: 'Round Score',
            endValue: pointsEarned,
            suffix: ' pts',
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 500),
            isHighlighted: true,
            hapticInterval: 2,
          ),
          const SizedBox(height: 12),

          // Total Score
          AnimatedCounter(
            label: 'Total Score',
            endValue: score,
            startValue: score - pointsEarned,
            suffix: ' pts',
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 800),
            hapticInterval: 3,
          ),
          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: AppColors.accentGold.withAlpha(50),
          ),
          const SizedBox(height: 16),

          // Time Remaining
          AnimatedCounter(
            label: 'Time Remaining',
            endValue: timeRemaining,
            suffix: 's',
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 1100),
            hapticInterval: 5,
          ),
          const SizedBox(height: 12),

          // Next Round Time - highlight the bonus calculation
          _NextRoundCounter(
            timeRemaining: timeRemaining,
            pointsEarned: pointsEarned,
          ),
        ],
      ),
    );
  }
}

/// Special counter for next round that shows the time bonus animation
/// Formula: timeRemaining + roundScore
class _NextRoundCounter extends StatefulWidget {
  const _NextRoundCounter({
    required this.timeRemaining,
    required this.pointsEarned,
  });

  final int timeRemaining;
  final int pointsEarned;

  @override
  State<_NextRoundCounter> createState() => _NextRoundCounterState();
}

class _NextRoundCounterState extends State<_NextRoundCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _timeAnimation;
  bool _started = false;
  bool _showFormula = false;

  /// Calculate clutch multiplier based on remaining time
  /// ≤10s: 2x, 11-20s: 1.5x, >20s: 1x
  double get _clutchMultiplier {
    if (widget.timeRemaining <= 10) return 2.0;
    if (widget.timeRemaining <= 20) return 1.5;
    return 1.0;
  }

  int get _adjustedTime => (widget.timeRemaining * _clutchMultiplier).round();
  int get _endTime => _adjustedTime + widget.pointsEarned;
  int get _totalBonus => _endTime - widget.timeRemaining;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Formula: (time × multiplier) + round score
    _timeAnimation = Tween<double>(
      begin: widget.timeRemaining.toDouble(),
      end: _endTime.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _timeAnimation.addListener(_onAnimationUpdate);

    // Start after delay
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _started = true;
          _showFormula = true;
        });
        _controller.forward();
      }
    });
  }

  int _lastHapticValue = 0;

  void _onAnimationUpdate() {
    final currentValue = _timeAnimation.value.round();
    if ((currentValue - _lastHapticValue).abs() >= 2) {
      HapticService.instance.light();
      _lastHapticValue = currentValue;
    }

    // Strong haptic at the end
    if (_controller.isCompleted) {
      HapticService.instance.success();
    }
  }

  @override
  void dispose() {
    _timeAnimation.removeListener(_onAnimationUpdate);
    _controller.dispose();
    super.dispose();
  }

  /// Build formula string based on clutch multiplier
  String get _formulaString {
    final time = widget.timeRemaining;
    final pts = widget.pointsEarned;
    final mult = _clutchMultiplier;

    if (mult > 1.0) {
      // Show multiplier: "8s × 2 + 65 pts = 81s"
      final multStr = mult == 2.0 ? '×2' : '×1.5';
      return '${time}s $multStr + $pts pts = ${_endTime}s';
    } else {
      // No multiplier: "30s + 65 pts = 95s"
      return '${time}s + $pts pts = ${_endTime}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _started ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          // Formula breakdown
          if (_showFormula)
            AnimatedOpacity(
              opacity: _controller.value > 0.1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formulaString,
                  style: GoogleFonts.exo2(
                    color: AppColors.accentGold.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Next Round result
          AnimatedBuilder(
            animation: _timeAnimation,
            builder: (context, child) {
              final value = _timeAnimation.value.round();

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Round',
                    style: GoogleFonts.exo2(
                      color: Colors.white.withAlpha(180),
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value}s',
                        style: GoogleFonts.orbitron(
                          color: AppColors.accentGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Show total bonus (clutch time bonus + round score)
                      if (_controller.isCompleted && _totalBonus > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withAlpha(50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+$_totalBonus',
                            style: GoogleFonts.orbitron(
                              color: AppColors.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
