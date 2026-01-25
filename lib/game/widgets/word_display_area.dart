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
    required this.letters,
    this.committedWord = '',
    this.celebrate = false,
    this.shake = false,
    this.pendingLetterId,
    this.letterDwellStartTime,
  });

  /// Selected letters (current drag), where null represents a space
  final List<LetterNode?> selectedLetters;

  /// All available letters (to look up pending letter)
  final List<LetterNode> letters;

  /// Already committed word segments (locked in via space)
  final String committedWord;

  /// Trigger celebration animation (correct answer)
  final bool celebrate;

  /// Trigger shake animation (wrong answer)
  final bool shake;

  /// Letter ID currently being dwelled on (for target indicator)
  final int? pendingLetterId;

  /// When dwell started on the pending letter
  final DateTime? letterDwellStartTime;

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

  /// Get the target letter being dwelled on (if any)
  String? get _targetLetter {
    if (widget.pendingLetterId == null) return null;
    // Don't show if already selected
    if (widget.selectedLetters.any((l) => l?.id == widget.pendingLetterId)) return null;
    // Mystery orbs have IDs 100+
    if (widget.pendingLetterId! >= 100) return '?';

    final letter = widget.letters.firstWhere(
      (l) => l.id == widget.pendingLetterId,
      orElse: () => const LetterNode(id: -1, letter: '', points: 0, position: Offset.zero),
    );
    return letter.letter.isNotEmpty ? letter.letter.toUpperCase() : null;
  }

  /// Build the active selection area (landing zone for letters)
  Widget _buildActiveSelectionArea(
    BuildContext context,
    bool hasContent,
    bool hasActiveSelection,
  ) {
    final targetLetter = _targetLetter;
    final showTargetIndicator = targetLetter != null;

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
              vertical: AppSpacing.sm,
            ),
            // Fixed height to accommodate 2 rows without jarring resize
            height: 120,
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
            child: _buildSelectionContent(
              hasContent: hasContent,
              hasActiveSelection: hasActiveSelection,
              showTargetIndicator: showTargetIndicator,
              targetLetter: targetLetter,
              bubbleSize: bubbleSize,
            ),
          ),
        );
      },
    );
  }

  /// Build the content inside the selection area
  Widget _buildSelectionContent({
    required bool hasContent,
    required bool hasActiveSelection,
    required bool showTargetIndicator,
    required String? targetLetter,
    required double bubbleSize,
  }) {
    // No selection yet - show placeholder or target indicator
    if (!hasActiveSelection) {
      if (showTargetIndicator && targetLetter != null) {
        // Show target indicator centered when no selection yet
        return Center(
          child: _TargetLetterIndicator(
            letter: targetLetter,
            dwellStartTime: widget.letterDwellStartTime,
            size: 44.0,
          ),
        );
      }
      return Center(
        child: Text(
          hasContent ? 'Continue spelling...' : 'Connect letters...',
          style: TextStyle(
            color: AppColors.white.withAlpha(128),
            fontSize: 16,
          ),
        ),
      );
    }

    // Build letter widgets
    final letterWidgets = widget.selectedLetters.asMap().entries.map((entry) {
      final index = entry.key;
      final letter = entry.value;
      return _buildAnimatedLetter(letter, bubbleSize, index);
    }).toList();

    // Add target indicator as last item in flow (if showing)
    if (showTargetIndicator && targetLetter != null) {
      letterWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: _TargetLetterIndicator(
            letter: targetLetter,
            dwellStartTime: widget.letterDwellStartTime,
            size: bubbleSize.clamp(36.0, 44.0),
          ),
        ),
      );
    }

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 0,
        runSpacing: AppSpacing.xs,
        children: letterWidgets,
      ),
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

/// Target letter indicator with circular progress ring
class _TargetLetterIndicator extends StatefulWidget {
  const _TargetLetterIndicator({
    required this.letter,
    required this.size,
    this.dwellStartTime,
  });

  final String letter;
  final double size;
  final DateTime? dwellStartTime;

  @override
  State<_TargetLetterIndicator> createState() => _TargetLetterIndicatorState();
}

class _TargetLetterIndicatorState extends State<_TargetLetterIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: HitDetectionConfig.dwellTimeMs),
    );
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _startFromCurrentProgress();
  }

  void _startFromCurrentProgress() {
    if (widget.dwellStartTime != null) {
      final elapsed = DateTime.now().difference(widget.dwellStartTime!);
      final startProgress = (elapsed.inMilliseconds / HitDetectionConfig.dwellTimeMs).clamp(0.0, 1.0);
      _controller.forward(from: startProgress);
    } else {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(_TargetLetterIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.letter != oldWidget.letter || widget.dwellStartTime != oldWidget.dwellStartTime) {
      _startFromCurrentProgress();
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
      animation: _progress,
      builder: (context, child) {
        final progress = _progress.value;
        // Opacity increases from 0.5 to 1.0
        final opacity = 0.5 + (progress * 0.5);
        // Glow intensity increases with progress
        final glowAlpha = (progress * 200).toInt();

        return Opacity(
          opacity: opacity,
          child: SizedBox(
            width: widget.size + 12,
            height: widget.size + 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular progress ring
                CustomPaint(
                  size: Size(widget.size + 12, widget.size + 12),
                  painter: _DwellProgressPainter(
                    progress: progress,
                    color: AppColors.accentCyan,
                    strokeWidth: 3.0,
                  ),
                ),
                // Letter bubble with glow
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryDarkPurple,
                    border: Border.all(
                      color: AppColors.accentCyan,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withAlpha(glowAlpha),
                        blurRadius: 12 + (progress * 8),
                        spreadRadius: 2 + (progress * 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.letter,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.size * 0.45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for circular dwell progress indicator
class _DwellProgressPainter extends CustomPainter {
  _DwellProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
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
    final trackPaint = Paint()
      ..color = color.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from top (-90 degrees) and sweep clockwise
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_DwellProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
