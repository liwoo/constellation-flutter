import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';

/// A slot-machine style category selector with jackpot effect
class CategoryJackpot extends StatefulWidget {
  const CategoryJackpot({
    super.key,
    required this.targetCategory,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 2500),
  });

  /// The category to land on
  final String targetCategory;

  /// Callback when animation completes
  final VoidCallback onComplete;

  /// Duration of the spinning animation
  final Duration duration;

  @override
  State<CategoryJackpot> createState() => _CategoryJackpotState();
}

class _CategoryJackpotState extends State<CategoryJackpot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final _categories = CategoryDictionary.categories;
  int _displayIndex = 0;
  Timer? _spinTimer;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    );

    _startSpinning();
  }

  void _startSpinning() {
    // Start with fast spinning (50ms intervals)
    // Gradually slow down based on animation progress
    _controller.forward();

    _updateDisplay();
  }

  void _updateDisplay() {
    if (_isComplete) return;

    final progress = _animation.value;

    // Calculate delay based on progress (starts fast, slows down)
    // 50ms -> 300ms as progress goes 0 -> 1
    final delay = Duration(milliseconds: (50 + (250 * progress)).toInt());

    _spinTimer = Timer(delay, () {
      if (!mounted) return;

      if (progress >= 0.95) {
        // Land on target
        setState(() {
          _displayIndex = _categories.indexOf(widget.targetCategory);
          _isComplete = true;
        });
        widget.onComplete();
      } else {
        // Random category
        setState(() {
          _displayIndex = Random().nextInt(_categories.length);
        });
        _updateDisplay();
      }
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _categories[_displayIndex];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPurple.withAlpha(200),
                AppColors.primaryDarkPurple.withAlpha(200),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isComplete
                  ? AppColors.accentGold
                  : Colors.white.withAlpha(100),
              width: _isComplete ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isComplete
                    ? AppColors.accentGold.withAlpha(100)
                    : AppColors.black.withAlpha(80),
                blurRadius: _isComplete ? 20 : 10,
                spreadRadius: _isComplete ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Text(
                'CATEGORY',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              // Category display
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 50),
                child: Text(
                  currentCategory,
                  key: ValueKey(currentCategory),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: _isComplete
                            ? AppColors.accentGold.withAlpha(200)
                            : AppColors.black.withAlpha(100),
                        blurRadius: _isComplete ? 10 : 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A simpler inline category spinner for smaller displays
class CategorySpinner extends StatefulWidget {
  const CategorySpinner({
    super.key,
    required this.targetCategory,
    required this.onComplete,
  });

  final String targetCategory;
  final VoidCallback onComplete;

  @override
  State<CategorySpinner> createState() => _CategorySpinnerState();
}

class _CategorySpinnerState extends State<CategorySpinner> {
  final _categories = CategoryDictionary.categories;
  int _currentIndex = 0;
  Timer? _timer;
  int _tickCount = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startSpinning();
  }

  void _startSpinning() {
    // 20 ticks total, slowing down as we go
    _tick();
  }

  void _tick() {
    if (_tickCount >= 20) {
      // Final tick - land on target
      setState(() {
        _currentIndex = _categories.indexOf(widget.targetCategory);
        _isComplete = true;
      });
      widget.onComplete();
      return;
    }

    // Calculate delay: 50ms for first 10, then slow down
    final delay = _tickCount < 10
        ? 50
        : 50 + ((_tickCount - 10) * 30); // 50, 80, 110, 140...

    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _currentIndex = Random().nextInt(_categories.length);
        _tickCount++;
      });
      _tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 100),
      style: TextStyle(
        color: _isComplete ? AppColors.accentGold : Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      child: Text(_categories[_currentIndex]),
    );
  }
}
