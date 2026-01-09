import 'package:flutter/material.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';

class WordDisplayArea extends StatelessWidget {
  const WordDisplayArea({
    super.key,
    required this.selectedLetters,
  });

  final List<LetterNode> selectedLetters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Word container with golden border
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: AppColors.primaryDarkPurple.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(
              color: AppColors.accentGold,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: selectedLetters.isEmpty
                ? [
                    Text(
                      'Connect letters...',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ]
                : selectedLetters
                    .map((letter) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: LetterBubble(
                            letter: letter.letter,
                            points: letter.points,
                            isSelected: true,
                            size: 50,
                          ),
                        ))
                    .toList(),
          ),
        ),

        // Small triangle constellation decoration
        const SizedBox(height: AppSpacing.sm),
        CustomPaint(
          size: const Size(40, 20),
          painter: _TriangleConstellationPainter(),
        ),
      ],
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

    // Triangle points
    final p1 = Offset(size.width / 2, 0);
    final p2 = Offset(0, size.height);
    final p3 = Offset(size.width, size.height);

    // Draw lines
    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p2, p3, paint);
    canvas.drawLine(p3, p1, paint);

    // Draw dots
    canvas.drawCircle(p1, 3, dotPaint);
    canvas.drawCircle(p2, 3, dotPaint);
    canvas.drawCircle(p3, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
