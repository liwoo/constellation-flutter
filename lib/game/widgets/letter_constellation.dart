import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/connection_painter.dart';
import 'package:constellation_app/game/widgets/star_shimmer.dart';

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
    // Letter dwell progress
    this.pendingLetterId,
    this.letterDwellStartTime,
    this.lastConnectedLetterId,
    // Pure connection celebration
    this.showConnectionAnimation = false,
    // Round-start shimmer
    this.shimmerPaths = const [],
    this.shimmerPaused = false,
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

  // Letter dwell progress
  final int? pendingLetterId; // Letter being hovered
  final DateTime? letterDwellStartTime; // When dwell started on letter
  final int? lastConnectedLetterId; // For connection flash animation

  // Pure connection celebration
  final bool showConnectionAnimation; // Trigger path celebration animation

  // Round-start shimmer: star paths of a few answers, traced once, quickly
  final List<List<int>> shimmerPaths;
  final bool shimmerPaused; // Hold the shimmer while the board is hidden

  @override
  State<LetterConstellation> createState() => _LetterConstellationState();
}

class _LetterConstellationState extends State<LetterConstellation>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  // Round-start shimmer
  late final AnimationController _shimmerController =
      AnimationController(vsync: this)..addListener(_shimmerChime);
  String _lastChime = '';

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: AnimationConfig.pureConnectionAnimationDuration),
      vsync: this,
    );
    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.easeInOut),
    );
    _startShimmer();
  }

  /// Identity of a set of shimmer paths (new category = new shimmer)
  static String _shimmerKey(List<List<int>> paths) =>
      paths.map((p) => p.join(',')).join('|');

  int get _shimmerTotalMs => WordPreviewConfig.totalMs(widget.shimmerPaths);

  void _startShimmer() {
    _lastChime = '';
    _shimmerController.stop();
    if (widget.shimmerPaths.isEmpty) {
      _shimmerController.value = 1;
      return;
    }
    _shimmerController
      ..duration = Duration(milliseconds: _shimmerTotalMs)
      ..value = 0;
    if (!widget.shimmerPaused) _shimmerController.forward();
  }

  ShimmerFrame? get _shimmerFrame {
    if (!_shimmerController.isAnimating && _shimmerController.value == 0) {
      return null; // Waiting for the pause screen to close
    }
    return ShimmerFrame.at(
      widget.shimmerPaths,
      _shimmerController.value * _shimmerTotalMs,
    );
  }

  /// Faint rising twinkle as each star lights
  void _shimmerChime() {
    final frame = _shimmerFrame;
    if (frame == null || frame.fade < 1) return;
    final key = '${identityHashCode(frame.path)}-${frame.headIndex}';
    if (key == _lastChime) return;
    _lastChime = key;
    AudioService.instance.play(
      GameSound.counterTick,
      volume: 0.9,
      rate: 1.2 + frame.headIndex * 0.12,
      minInterval: Duration.zero,
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

    if (_shimmerKey(widget.shimmerPaths) != _shimmerKey(oldWidget.shimmerPaths)) {
      _startShimmer();
    } else if (widget.shimmerPaused != oldWidget.shimmerPaused) {
      if (widget.shimmerPaused) {
        _shimmerController.stop();
      } else if (_shimmerController.value < 1 && widget.shimmerPaths.isNotEmpty) {
        _shimmerController.forward();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
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

  /// Calculate dwell progress for a letter (0.0 to 1.0)
  double _getLetterDwellProgress(int letterId) {
    if (widget.pendingLetterId != letterId) return 0.0;
    if (widget.letterDwellStartTime == null) return 0.0;

    const dwellDuration = Duration(milliseconds: HitDetectionConfig.dwellTimeMs);
    final elapsed = DateTime.now().difference(widget.letterDwellStartTime!);
    return (elapsed.inMilliseconds / dwellDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// While a hint plays, everything outside the hinted word fades back
  bool get _isHintActive => widget.hintLetterIds.isNotEmpty;

  /// Opacity for a star/orb - dimmed if a hint is showing a different word
  double _hintFocusOpacity(int id) {
    if (!_isHintActive) return 1.0;
    return widget.hintLetterIds.contains(id) ? 1.0 : 0.15;
  }

  /// Calculate bubble size based on device screen size (not container)
  /// This ensures letters don't shrink when word display area changes
  double _calculateBubbleSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final minDimension = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;

    // Sized so a full 26-star board still leaves clear space between stars
    final calculatedSize = minDimension * LayoutConfig.starSizeFraction;

    // Clamp to reasonable bounds
    return calculatedSize.clamp(LayoutConfig.minStarSize, LayoutConfig.maxStarSize);
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

            // Star centres in pixels, for the round-start shimmer
            final starCenters = <int, Offset>{
              for (final l in widget.letters)
                l.id: Offset(l.position.dx * containerSize.width, l.position.dy * containerSize.height),
              for (final o in widget.mysteryOrbs)
                if (o.isActive)
                  o.id: Offset(o.position.dx * containerSize.width, o.position.dy * containerSize.height),
            };

            Widget shimmerLayer({required bool front}) => Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) => CustomPaint(
                        painter: StarShimmerPainter(
                          frame: _shimmerFrame,
                          centers: starCenters,
                          starSize: bubbleSize,
                          front: front,
                        ),
                      ),
                    ),
                  ),
                );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Use onTapDown for immediate response to taps (fires before pan recognition)
              // This fixes the bug where the first letter doesn't respond after category load
              onTapDown: (details) {
                final relativePosition = Offset(
                  details.localPosition.dx / containerSize.width,
                  details.localPosition.dy / containerSize.height,
                );
                widget.onDragStart(relativePosition);
              },
              onTapUp: (_) => widget.onDragEnd(),
              onTapCancel: () => widget.onDragEnd(),
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

                  // Shimmer halo + trace, behind the stars
                  shimmerLayer(front: false),

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
                        child: AnimatedOpacity(
                          opacity: _hintFocusOpacity(orb.id),
                          duration: const Duration(milliseconds: 250),
                          child: MysteryOrbWidget(
                            size: bubbleSize, // Same size as letter bubbles
                            isActive: orb.isActive,
                            isApproaching: isApproaching,
                            dwellProgress: dwellProgress,
                          ),
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
                    final dwellProgress = _getLetterDwellProgress(letter.id);
                    final justConnected = widget.lastConnectedLetterId == letter.id;

                    return Positioned(
                      left: x - (bubbleSize / 2),
                      top: y - (bubbleSize / 2),
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _hintFocusOpacity(letter.id),
                          duration: const Duration(milliseconds: 250),
                          child: LetterBubble(
                            letter: letter.letter,
                            points: letter.points,
                            isSelected: isSelected,
                            isStartingLetter: isStarting && !_isHintActive,
                            isHintLetter: isHint,
                            isApproaching: isApproaching,
                            dwellProgress: dwellProgress,
                            justConnected: justConnected,
                            size: bubbleSize,
                          ),
                        ),
                      ),
                    );
                  }),

                  // Shimmer rings + sparkles, over the stars
                  shimmerLayer(front: true),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
