import 'package:flutter/material.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
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
    this.hintWord,
  });

  final List<LetterNode> letters;
  final List<int> selectedLetterIds;
  final void Function(Offset relativePosition) onDragStart;
  final void Function(Offset relativePosition) onDragUpdate;
  final VoidCallback onDragEnd;
  final Offset? currentDragPosition;
  final bool isDragging;
  final String? startingLetter; // Letter to highlight as starting point
  final String? hintWord; // Word to animate as hint

  /// Get the set of letters that are part of the hint word
  Set<String> get _hintLetters {
    if (hintWord == null) return {};
    // Get unique letters from the hint word (ignoring spaces)
    return hintWord!.toUpperCase().replaceAll(' ', '').split('').toSet();
  }

  /// Calculate dynamic bubble size based on container dimensions
  /// Fits 26 letters with proper spacing
  double _calculateBubbleSize(Size containerSize) {
    // For 26 letters, we need roughly 6 columns and 5 rows
    // Use the smaller dimension to ensure bubbles fit
    final minDimension = containerSize.width < containerSize.height
        ? containerSize.width
        : containerSize.height;

    // Bubble size is approximately 1/7 of the smaller dimension
    // This allows for 6 bubbles with spacing
    final calculatedSize = minDimension / 7.5;

    // Clamp to reasonable bounds
    return calculatedSize.clamp(36.0, 70.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Calculate dynamic bubble size based on screen
        final bubbleSize = _calculateBubbleSize(containerSize);

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

              // Letter bubbles with dynamic sizing
              ...letters.map((letter) {
                final x = letter.position.dx * constraints.maxWidth;
                final y = letter.position.dy * constraints.maxHeight;
                final isSelected = selectedLetterIds.contains(letter.id);
                final isStarting = startingLetter != null &&
                    letter.letter.toUpperCase() == startingLetter!.toUpperCase();
                final isHint = _hintLetters.contains(letter.letter.toUpperCase());

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
