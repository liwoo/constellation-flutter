import 'package:flutter/material.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/connection_painter.dart';

class LetterConstellation extends StatelessWidget {
  const LetterConstellation({
    super.key,
    required this.letters,
    required this.selectedLetterIds,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.currentDragPosition,
    this.isDragging = false,
  });

  final List<LetterNode> letters;
  final List<int> selectedLetterIds;
  final void Function(Offset relativePosition) onDragStart;
  final void Function(Offset relativePosition) onDragUpdate;
  final VoidCallback onDragEnd;
  final Offset? currentDragPosition;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Get positions of selected letters for drawing connections
        final selectedPositions = selectedLetterIds
            .map((id) => letters.firstWhere((l) => l.id == id))
            .map((node) => node.position)
            .toList();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final relativePosition = Offset(
              details.localPosition.dx / containerSize.width,
              details.localPosition.dy / containerSize.height,
            );
            onDragStart(relativePosition);
          },
          onPanUpdate: (details) {
            final relativePosition = Offset(
              details.localPosition.dx / containerSize.width,
              details.localPosition.dy / containerSize.height,
            );
            onDragUpdate(relativePosition);
          },
          onPanEnd: (_) => onDragEnd(),
          onPanCancel: () => onDragEnd(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Connection lines (drawn first, behind bubbles)
              Positioned.fill(
                child: CustomPaint(
                  painter: ConnectionPainter(
                    points: selectedPositions,
                    containerSize: containerSize,
                    currentDragPosition: currentDragPosition,
                    isDragging: isDragging,
                  ),
                ),
              ),

              // Letter bubbles
              ...letters.map((letter) {
                final x = letter.position.dx * constraints.maxWidth;
                final y = letter.position.dy * constraints.maxHeight;
                final isSelected = selectedLetterIds.contains(letter.id);

                return Positioned(
                  left: x - (AppConstants.letterBubbleSize / 2),
                  top: y - (AppConstants.letterBubbleSize / 2),
                  child: IgnorePointer(
                    child: LetterBubble(
                      letter: letter.letter,
                      points: letter.points,
                      isSelected: isSelected,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
