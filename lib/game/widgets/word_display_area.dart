import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';

class WordDisplayArea extends StatefulWidget {
  const WordDisplayArea({
    super.key,
    required this.selectedLetters,
    this.committedWord = '',
    this.celebrate = false,
    this.shake = false,
  });

  /// Selected letters (current drag), where null represents a space
  final List<LetterNode?> selectedLetters;

  /// Already committed word segments (locked in via space)
  final String committedWord;

  /// Trigger celebration animation (correct answer)
  final bool celebrate;

  /// Trigger shake animation (wrong answer)
  final bool shake;

  @override
  State<WordDisplayArea> createState() => _WordDisplayAreaState();
}

class _WordDisplayAreaState extends State<WordDisplayArea>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _shakeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    // Celebration (bounce) animation
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeInOut,
    ));

    // Shake animation (wrong answer)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -3.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(WordDisplayArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger celebration when celebrate becomes true
    if (widget.celebrate && !oldWidget.celebrate) {
      _celebrationController.forward(from: 0.0);
    }
    // Trigger shake when shake becomes true
    if (widget.shake && !oldWidget.shake) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Parse committed word into separate word segments
  List<String> get _bankedWords {
    if (widget.committedWord.isEmpty) return [];
    return widget.committedWord.trim().split(' ').where((w) => w.isNotEmpty).toList();
  }

  /// Calculate dynamic bubble size to fit all letters without overflow
  double _calculateBubbleSize(double availableWidth, int totalCharCount) {
    if (totalCharCount == 0) return 50.0;

    const horizontalPadding = AppSpacing.lg * 2;
    const letterSpacing = AppSpacing.xs * 2;

    final totalSpacing = horizontalPadding + (totalCharCount * letterSpacing);
    final availableForBubbles = availableWidth - totalSpacing;
    final maxBubbleSize = availableForBubbles / totalCharCount;

    return maxBubbleSize.clamp(28.0, 50.0);
  }

  /// Build a subtle banked word chip
  Widget _buildBankedWordChip(String word, int index) {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        // Stagger the dance animation for each chip
        final delay = index * 0.15;
        final progress = (_celebrationController.value - delay).clamp(0.0, 1.0);
        final bounce = progress > 0 ? math.sin(progress * math.pi * 3) * 6 * (1 - progress) : 0.0;

        return Transform.translate(
          offset: Offset(0, bounce),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentGold.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accentGold.withAlpha(120),
            width: 1,
          ),
        ),
        child: Text(
          word,
          style: TextStyle(
            color: AppColors.accentGold.withAlpha(220),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankedWords = _bankedWords;
    final hasBankedWords = bankedWords.isNotEmpty;
    final hasActiveSelection = widget.selectedLetters.isNotEmpty;
    final hasContent = hasBankedWords || hasActiveSelection;

    return Column(
      children: [
        // Subtle banked word chips (inline, minimal)
        if (hasBankedWords) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: bankedWords
                  .asMap()
                  .entries
                  .map((e) => _buildBankedWordChip(e.value, e.key))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],

        // Active selection area (landing zone for current drag)
        _buildActiveSelectionArea(context, hasContent, hasActiveSelection),

        // Small triangle constellation decoration
        const SizedBox(height: AppSpacing.sm),
        CustomPaint(
          size: const Size(40, 20),
          painter: _TriangleConstellationPainter(),
        ),
      ],
    );
  }

  /// Build the active selection area (landing zone for letters)
  Widget _buildActiveSelectionArea(
    BuildContext context,
    bool hasContent,
    bool hasActiveSelection,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bubbleSize = _calculateBubbleSize(
          constraints.maxWidth - (AppSpacing.lg * 2),
          widget.selectedLetters.length,
        );

        return AnimatedBuilder(
          animation: Listenable.merge([_bounceAnimation, _shakeAnimation]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, _bounceAnimation.value),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            constraints: const BoxConstraints(minHeight: 70),
            decoration: BoxDecoration(
              color: AppColors.primaryDarkPurple.withAlpha(153),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(
                color: hasActiveSelection
                    ? AppColors.accentGold
                    : AppColors.accentGold.withAlpha(100),
                width: 2,
              ),
            ),
            child: !hasActiveSelection
                ? Center(
                    child: Text(
                      hasContent ? 'Continue spelling...' : 'Connect letters...',
                      style: TextStyle(
                        color: AppColors.white.withAlpha(128),
                        fontSize: 16,
                      ),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    spacing: 0,
                    runSpacing: AppSpacing.xs,
                    children: widget.selectedLetters.asMap().entries.map((entry) {
                      final index = entry.key;
                      final letter = entry.value;
                      return _buildAnimatedLetter(letter, bubbleSize, index);
                    }).toList(),
                  ),
          ),
        );
      },
    );
  }

  /// Build an animated letter bubble that dances on celebration
  Widget _buildAnimatedLetter(LetterNode? letter, double bubbleSize, int index) {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        // Stagger the dance - each letter starts slightly after the previous
        final delay = index * 0.08;
        final progress = (_celebrationController.value - delay).clamp(0.0, 1.0);

        // Dance animation: bounce + slight rotation
        final bounce = progress > 0
            ? math.sin(progress * math.pi * 4) * 10 * (1 - progress)
            : 0.0;
        final rotation = progress > 0
            ? math.sin(progress * math.pi * 3) * 0.15 * (1 - progress)
            : 0.0;
        final scale = progress > 0
            ? 1.0 + math.sin(progress * math.pi * 2) * 0.1 * (1 - progress)
            : 1.0;

        return Transform.translate(
          offset: Offset(0, bounce),
          child: Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: letter == null
            ? _buildSpaceIndicator(bubbleSize)
            : LetterBubble(
                letter: letter.letter,
                points: letter.points,
                isSelected: true,
                size: bubbleSize,
              ),
      ),
    );
  }

  /// Build a visual indicator for a space in the word
  Widget _buildSpaceIndicator(double size) {
    return Container(
      width: size * 0.6,
      height: size,
      alignment: Alignment.center,
      child: Container(
        width: size * 0.4,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.accentGold.withAlpha(150),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _TriangleConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGold
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.fill;

    final p1 = Offset(size.width / 2, 0);
    final p2 = Offset(0, size.height);
    final p3 = Offset(size.width, size.height);

    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p2, p3, paint);
    canvas.drawLine(p3, p1, paint);

    canvas.drawCircle(p1, 3, dotPaint);
    canvas.drawCircle(p2, 3, dotPaint);
    canvas.drawCircle(p3, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
