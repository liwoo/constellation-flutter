import 'package:flutter/material.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/theme/theme.dart';
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
    this.startingLetter,
    this.hintLetterIds = const [],
    this.hintAnimationIndex = 0,
    this.approachingLetterIds = const [],
  });

  final List<LetterNode> letters;
  final List<int> selectedLetterIds;
  final void Function(Offset relativePosition) onDragStart;
  final void Function(Offset relativePosition) onDragUpdate;
  final VoidCallback onDragEnd;
  final Offset? currentDragPosition;
  final bool isDragging;
  final String? startingLetter; // Letter to highlight as starting point
  final List<int> hintLetterIds; // Letter node IDs in order for hint animation
  final int hintAnimationIndex; // Current position in the hint animation
  final List<int> approachingLetterIds; // Letter IDs being hovered over

  /// Check if a letter should be highlighted as hint (already revealed in sequence)
  bool _isHintLetter(int letterId) {
    if (hintLetterIds.isEmpty) return false;
    // Only highlight letters up to the current animation index
    final visibleHintIds = hintLetterIds.take(hintAnimationIndex).toSet();
    return visibleHintIds.contains(letterId);
  }

  /// Calculate bubble size based on device screen size (not container)
  /// This ensures letters don't shrink when word display area changes
  double _calculateBubbleSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final minDimension = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;

    // Bubble size is approximately 1/7 of the smaller screen dimension
    final calculatedSize = minDimension / 7.5;

    // Clamp to reasonable bounds
    return calculatedSize.clamp(36.0, 70.0);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bubble size from screen size (constant for this device)
    final bubbleSize = _calculateBubbleSize(context);

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

              // Letter bubbles - static positions, no movement
              ...letters.map((letter) {
                final x = letter.position.dx * constraints.maxWidth;
                final y = letter.position.dy * constraints.maxHeight;
                final isSelected = selectedLetterIds.contains(letter.id);
                final isStarting = startingLetter != null &&
                    letter.letter.toUpperCase() == startingLetter!.toUpperCase();
                final isHint = _isHintLetter(letter.id);
                final isApproaching = approachingLetterIds.contains(letter.id);

                return Positioned(
                  left: x - (bubbleSize / 2),
                  top: y - (bubbleSize / 2),
                  child: IgnorePointer(
                    child: LetterBubble(
                      letter: letter.letter,
                      points: letter.points,
                      isSelected: isSelected,
                      isStartingLetter: isStarting,
                      isHintLetter: isHint,
                      isApproaching: isApproaching,
                      size: bubbleSize,
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
