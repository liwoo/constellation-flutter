import 'package:flutter/material.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/connection_painter.dart';

class LetterConstellation extends StatefulWidget {
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
    // Mystery orb props
    this.mysteryOrbs = const [],
    this.pendingMysteryOrbId,
    this.mysteryOrbDwellStartTime,
    // Pure connection celebration
    this.showConnectionAnimation = false,
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

  // Mystery orb state
  final List<MysteryOrb> mysteryOrbs;
  final int? pendingMysteryOrbId; // Orb being hovered
  final DateTime? mysteryOrbDwellStartTime; // When dwell started

  // Pure connection celebration
  final bool showConnectionAnimation; // Trigger path celebration animation

  @override
  State<LetterConstellation> createState() => _LetterConstellationState();
}

class _LetterConstellationState extends State<LetterConstellation>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Longer for dramatic effect
      vsync: this,
    );
    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LetterConstellation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger celebration when showConnectionAnimation becomes true
    if (widget.showConnectionAnimation && !oldWidget.showConnectionAnimation) {
      _celebrationController.forward(from: 0.0);
    } else if (!widget.showConnectionAnimation && oldWidget.showConnectionAnimation) {
      _celebrationController.reset();
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  /// Check if a letter should be highlighted as hint (already revealed in sequence)
  bool _isHintLetter(int letterId) {
    if (widget.hintLetterIds.isEmpty) return false;
    // Only highlight letters up to the current animation index
    final visibleHintIds = widget.hintLetterIds.take(widget.hintAnimationIndex).toSet();
    return visibleHintIds.contains(letterId);
  }

  /// Calculate dwell progress for a mystery orb (0.0 to 1.0)
  double _getMysteryOrbDwellProgress(int orbId) {
    if (widget.pendingMysteryOrbId != orbId) return 0.0;
    if (widget.mysteryOrbDwellStartTime == null) return 0.0;

    const dwellDuration = Duration(seconds: 1);
    final elapsed = DateTime.now().difference(widget.mysteryOrbDwellStartTime!);
    return (elapsed.inMilliseconds / dwellDuration.inMilliseconds).clamp(0.0, 1.0);
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

    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final containerSize = Size(constraints.maxWidth, constraints.maxHeight);

            // Get positions of selected letters/orbs for drawing connections
            final selectedPositions = widget.selectedLetterIds
                .map((id) {
                  // Mystery orb IDs are 100+
                  if (id >= 100) {
                    final orb = widget.mysteryOrbs.firstWhere(
                      (o) => o.id == id,
                      orElse: () => const MysteryOrb(id: -1, position: Offset(0.5, 0.5)),
                    );
                    return orb.position;
                  }
                  final letter = widget.letters.firstWhere(
                    (l) => l.id == id,
                    orElse: () => const LetterNode(id: -1, letter: '', points: 0, position: Offset(0.5, 0.5)),
                  );
                  return letter.position;
                })
                .toList();

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                final relativePosition = Offset(
                  details.localPosition.dx / containerSize.width,
                  details.localPosition.dy / containerSize.height,
                );
                widget.onDragStart(relativePosition);
              },
              onPanUpdate: (details) {
                final relativePosition = Offset(
                  details.localPosition.dx / containerSize.width,
                  details.localPosition.dy / containerSize.height,
                );
                widget.onDragUpdate(relativePosition);
              },
              onPanEnd: (_) => widget.onDragEnd(),
              onPanCancel: () => widget.onDragEnd(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Connection lines (drawn first, behind bubbles)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ConnectionPainter(
                        points: selectedPositions,
                        containerSize: containerSize,
                        currentDragPosition: widget.currentDragPosition,
                        isDragging: widget.isDragging,
                        celebrationProgress: _celebrationAnimation.value,
                      ),
                    ),
                  ),

                  // Mystery orbs - rendered as part of constellation (same size as letters)
                  ...widget.mysteryOrbs.map((orb) {
                    final x = orb.position.dx * constraints.maxWidth;
                    final y = orb.position.dy * constraints.maxHeight;
                    final isApproaching = widget.pendingMysteryOrbId == orb.id;
                    final dwellProgress = _getMysteryOrbDwellProgress(orb.id);

                    return Positioned(
                      left: x - (bubbleSize / 2),
                      top: y - (bubbleSize / 2),
                      child: IgnorePointer(
                        child: MysteryOrbWidget(
                          size: bubbleSize, // Same size as letter bubbles
                          isActive: orb.isActive,
                          isApproaching: isApproaching,
                          dwellProgress: dwellProgress,
                        ),
                      ),
                    );
                  }),

                  // Letter bubbles - static positions, no movement
                  ...widget.letters.map((letter) {
                    final x = letter.position.dx * constraints.maxWidth;
                    final y = letter.position.dy * constraints.maxHeight;
                    final isSelected = widget.selectedLetterIds.contains(letter.id);
                    final isStarting = widget.startingLetter != null &&
                        letter.letter.toUpperCase() == widget.startingLetter!.toUpperCase();
                    final isHint = _isHintLetter(letter.id);
                    final isApproaching = widget.approachingLetterIds.contains(letter.id);

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
      },
    );
  }
}
