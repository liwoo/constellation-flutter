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

  /// Check if a letter should be highlighted as hint (already revealed in sequence)
  bool _isHintLetter(int letterId) {
    if (hintLetterIds.isEmpty) return false;
    // Only highlight letters up to the current animation index
    final visibleHintIds = hintLetterIds.take(hintAnimationIndex).toSet();
    return visibleHintIds.contains(letterId);
  }

  /// Find the letter node nearest to a position (within hit radius)
  LetterNode? _findNearestLetter(Offset relativePosition) {
    const hitRadius = 0.08; // Radius to detect nearby letter
    LetterNode? nearest;
    double minDistanceSq = hitRadius * hitRadius;

    for (final node in letters) {
      final dx = node.position.dx - relativePosition.dx;
      final dy = node.position.dy - relativePosition.dy;
      final distanceSq = dx * dx + dy * dy;
      if (distanceSq < minDistanceSq) {
        minDistanceSq = distanceSq;
        nearest = node;
      }
    }
    return nearest;
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

              // Letter bubbles - static positions, no movement
              ...letters.map((letter) {
                final x = letter.position.dx * constraints.maxWidth;
                final y = letter.position.dy * constraints.maxHeight;
                final isSelected = selectedLetterIds.contains(letter.id);
                final isStarting = startingLetter != null &&
                    letter.letter.toUpperCase() == startingLetter!.toUpperCase();
                final isHint = _isHintLetter(letter.id);

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

              // Floating letter indicator (iPhone keyboard style)
              // Shows letter above finger with two states:
              // - Passing through (white) vs Connected (gold)
              if (isDragging && currentDragPosition != null)
                Builder(
                  builder: (context) {
                    final nearestLetter = _findNearestLetter(currentDragPosition!);
                    if (nearestLetter == null) return const SizedBox.shrink();

                    // Check if this letter is already connected (selected)
                    final isConnected = selectedLetterIds.contains(nearestLetter.id);

                    // Position above the touch point
                    final touchX = currentDragPosition!.dx * containerSize.width;
                    final touchY = currentDragPosition!.dy * containerSize.height;

                    const offsetY = -75.0;
                    const indicatorSize = 56.0;

                    return Positioned(
                      left: touchX - (indicatorSize / 2),
                      top: touchY + offsetY,
                      child: IgnorePointer(
                        child: _FloatingLetterIndicator(
                          letter: nearestLetter.letter,
                          size: indicatorSize,
                          isConnected: isConnected,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Floating letter indicator that appears above the touch point
/// Like iOS keyboard - shows the letter you're hovering over
/// Two states: passing through (white) vs connected (gold)
class _FloatingLetterIndicator extends StatelessWidget {
  const _FloatingLetterIndicator({
    required this.letter,
    required this.size,
    this.isConnected = false,
  });

  final String letter;
  final double size;
  final bool isConnected; // True if letter is already selected/connected

  @override
  Widget build(BuildContext context) {
    // Different styles for connected vs passing through
    final backgroundColor = isConnected ? AppColors.accentGold : AppColors.white;
    final borderColor = isConnected ? AppColors.accentOrange : AppColors.accentGold;
    final textColor = isConnected ? AppColors.white : AppColors.black;
    final glowColor = isConnected
        ? AppColors.accentOrange.withAlpha(200)
        : AppColors.accentGold.withAlpha(150);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 15,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: AppColors.black.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
