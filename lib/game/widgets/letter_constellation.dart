import 'dart:math';

import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/connection_painter.dart';
import 'package:constellation_app/game/widgets/shooting_star.dart';
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
    // Shooting star bonus letter
    this.shootingStar,
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

  // Shooting star whose bonus letter is on the board (its node is in [letters])
  final ShootingStar? shootingStar;

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

  // Shooting star: the streak in, then a shimmer while it waits
  late final AnimationController _streakController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: ShootingStarConfig.streakMs),
  );
  late final AnimationController _comaController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.shootingStar != null) {
      _streakController.value = 1;
      _comaController.repeat();
    }
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

    if (widget.shootingStar != null && oldWidget.shootingStar == null) {
      _streakController.forward(from: 0);
      _comaController.repeat();
    } else if (widget.shootingStar == null && oldWidget.shootingStar != null) {
      _comaController.stop();
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
    _streakController.dispose();
    _comaController.dispose();
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

  LetterNode? get _shootingStarNode => widget.letters
      .where((l) => l.id == ShootingStarConfig.letterId)
      .firstOrNull;

  /// Flickers as it burns out
  double _shootingStarOpacity(ShootingStar star) {
    if (!star.isFading) return 1.0;
    return 0.45 + 0.55 * (0.5 + 0.5 * sin(_comaController.value * 6 * pi));
  }

  /// The bonus letter: pops in as the streak lands, wears a gold ring that
  /// runs down with its life, a "2x" tag, and flickers before burning out
  Widget _shootingStarBubble(Widget bubble, ShootingStar star, double size) {
    // Outside the cyan dwell ring so the two never overlap
    final ring = size + 20;
    return AnimatedBuilder(
      animation: Listenable.merge([_streakController, _comaController]),
      builder: (context, child) {
        final t = _streakController.value;
        final appear = t < 0.75 ? 0.0 : Curves.easeOutBack.transform((t - 0.75) / 0.25);
        return Opacity(
          opacity: (appear.clamp(0.0, 1.0) * _shootingStarOpacity(star)).clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.4 + 0.6 * appear, child: child),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          bubble,
          // Life left
          Positioned(
            left: -10,
            top: -10,
            width: ring,
            height: ring,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: star.secondsLeft / ShootingStarConfig.lifetimeSeconds),
              duration: const Duration(seconds: 1),
              builder: (context, life, _) => CustomPaint(
                painter: DwellRingPainter(
                  progress: life,
                  color: AppColors.accentGold,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentGold, AppColors.accentOrange],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: AppColors.black.withAlpha(120), blurRadius: 3),
                ],
              ),
              child: Text(
                '${ShootingStarConfig.scoreMultiplier}x',
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

                  // Shooting star comet - streaks in, then its tail lingers
                  if (widget.shootingStar case final star?)
                    if (_shootingStarNode case final node?)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_streakController, _comaController]),
                              builder: (context, _) => CustomPaint(
                                painter: ShootingStarPainter(
                                  from: Offset(
                                    star.from.dx * containerSize.width,
                                    star.from.dy * containerSize.height,
                                  ),
                                  to: Offset(
                                    node.position.dx * containerSize.width,
                                    node.position.dy * containerSize.height,
                                  ),
                                  streak: _streakController.value,
                                  glow: _comaController.value,
                                  starSize: bubbleSize,
                                  opacity: _shootingStarOpacity(star),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

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
                    final isShootingStar = letter.id == ShootingStarConfig.letterId;

                    Widget bubble = LetterBubble(
                      letter: letter.letter,
                      points: letter.points,
                      isSelected: isSelected,
                      isStartingLetter: isStarting && !_isHintActive && !isShootingStar,
                      isHintLetter: isHint,
                      isApproaching: isApproaching,
                      dwellProgress: dwellProgress,
                      justConnected: justConnected,
                      size: bubbleSize,
                    );
                    if (isShootingStar && widget.shootingStar != null) {
                      bubble = _shootingStarBubble(bubble, widget.shootingStar!, bubbleSize);
                    }

                    return Positioned(
                      left: x - (bubbleSize / 2),
                      top: y - (bubbleSize / 2),
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _hintFocusOpacity(letter.id),
                          duration: const Duration(milliseconds: 250),
                          child: bubble,
                        ),
                      ),
                    );
                  }),

                  // Shimmer rings + sparkles, over the stars
                  shimmerLayer(front: true),

                  // "Shooting star!" as one lands - in the strip under the
                  // lowest row, which stars never use
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ShootingStarCallout(
                        trigger: widget.shootingStar?.from, // Fixed for a star's whole life
                        title: 'SHOOTING STAR!',
                        subtitle: 'Use ${widget.shootingStar?.letter ?? ''} in your word for '
                            '${ShootingStarConfig.scoreMultiplier}x points',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
