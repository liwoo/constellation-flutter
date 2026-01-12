import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/constants/constants.dart';

/// Displays the target word with greyed-out letters that light up as matched
class TargetWordDisplay extends StatefulWidget {
  const TargetWordDisplay({
    super.key,
    required this.targetWord,
    required this.builtWord,
    this.showSuccess = false,
  });

  final String targetWord;
  final String builtWord;
  final bool showSuccess;

  @override
  State<TargetWordDisplay> createState() => _TargetWordDisplayState();
}

class _TargetWordDisplayState extends State<TargetWordDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(TargetWordDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSuccess && !oldWidget.showSuccess) {
      _celebrationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetChars = widget.targetWord.toUpperCase().split('');
    final builtChars = widget.builtWord.toUpperCase().split('');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryDarkPurple.withAlpha(100),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: widget.showSuccess
                ? AppColors.accentGold
                : AppColors.accentGold.withAlpha(60),
            width: widget.showSuccess ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // "Spell this word" label
            Text(
              'SPELL THIS WORD',
              style: TextStyle(
                color: AppColors.accentGold.withAlpha(180),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Target word with letters
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: List.generate(targetChars.length, (index) {
                final targetChar = targetChars[index];
                final isMatched = index < builtChars.length &&
                    builtChars[index] == targetChar;
                final isSpace = targetChar == ' ';

                return _buildTargetLetter(
                  targetChar,
                  isMatched: isMatched,
                  isSpace: isSpace,
                  index: index,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetLetter(
    String letter, {
    required bool isMatched,
    required bool isSpace,
    required int index,
  }) {
    if (isSpace) {
      return SizedBox(
        width: 16,
        height: 36,
        child: Center(
          child: Container(
            width: 12,
            height: 3,
            decoration: BoxDecoration(
              color: isMatched
                  ? AppColors.accentGold.withAlpha(150)
                  : Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        double bounce = 0;
        double rotation = 0;
        double scale = 1.0;

        if (widget.showSuccess) {
          final delay = index * 0.06;
          final progress = (_celebrationController.value - delay).clamp(0.0, 1.0);
          bounce = progress > 0
              ? math.sin(progress * math.pi * 4) * 8 * (1 - progress)
              : 0.0;
          rotation = progress > 0
              ? math.sin(progress * math.pi * 3) * 0.1 * (1 - progress)
              : 0.0;
          scale = progress > 0
              ? 1.0 + math.sin(progress * math.pi * 2) * 0.15 * (1 - progress)
              : 1.0;
        }

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
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isMatched
              ? AppColors.accentGold.withAlpha(40)
              : Colors.white.withAlpha(15),
          border: Border.all(
            color: isMatched
                ? AppColors.accentGold
                : Colors.white.withAlpha(50),
            width: isMatched ? 2 : 1,
          ),
          boxShadow: isMatched
              ? [
                  BoxShadow(
                    color: AppColors.accentGold.withAlpha(60),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              color: isMatched
                  ? AppColors.accentGold
                  : Colors.white.withAlpha(100),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
