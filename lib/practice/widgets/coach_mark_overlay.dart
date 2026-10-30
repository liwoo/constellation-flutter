import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/coach_targets.dart';
import 'package:constellation_app/practice/cubit/tutorial_cubit.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Dims the game, cuts a glowing spotlight around the UI being taught and
/// explains it. Action steps let touches through the spotlight only, so the
/// player presses the real button.
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({super.key, required this.targets});

  final CoachTargets targets;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addListener(_measureTarget);

  Rect? _hole;

  // False until the current step's target has been looked for once
  bool _measured = false;

  /// Track the target every frame - layout shifts (word area growing,
  /// banners animating) keep the spotlight glued to it
  void _measureTarget() {
    final target = context.read<TutorialCubit>().state.step?.target;
    final overlayBox = context.findRenderObject();
    Rect? rect;
    if (target != null && overlayBox is RenderBox && overlayBox.hasSize) {
      rect = widget.targets.rectOf(target, overlayBox);
    }
    if (rect != _hole || !_measured) {
      setState(() {
        _hole = rect;
        _measured = true;
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TutorialCubit, TutorialState>(
      listenWhen: (previous, current) => previous.step != current.step,
      listener: (context, state) {
        _hole = null;
        _measured = false;
        if (state.step == null) {
          _pulse.stop();
        } else {
          AudioService.instance.play(GameSound.buttonTap);
          _pulse.repeat();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _measureTarget();
          });
        }
      },
      builder: (context, state) {
        final step = state.step;
        if (step == null) return const SizedBox.shrink();

        // Wait a frame for the target to be measured before cutting a hole.
        // If it can't be found the card falls back to the centre (it still
        // offers SKIP TUTORIAL, so the player is never stuck).
        final hole = step.target == null ? null : _hole?.inflate(8);
        if (step.target != null && hole == null && !_measured) {
          return const _Barrier(hole: null, passThrough: false, child: SizedBox.expand());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return Stack(
              children: [
                Positioned.fill(
                  child: _Barrier(
                    hole: hole,
                    passThrough: step.requiresAction,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => CustomPaint(
                        painter: _SpotlightPainter(
                          hole: hole,
                          pulse: _pulse.value,
                          color: step.requiresAction
                              ? AppColors.accentGold
                              : AppColors.accentCyan,
                        ),
                      ),
                    ),
                  ),
                ),
                if (hole != null && step.requiresAction && hole.shortestSide < 140)
                  _buildPointer(hole),
                _positionCard(context, step, hole, size),
              ],
            );
          },
        );
      },
    );
  }

  /// Bouncing finger under small action targets
  Widget _buildPointer(Rect hole) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final bounce = sin(_pulse.value * 2 * pi) * 6;
        return Positioned(
          left: hole.center.dx - 4,
          top: hole.center.dy + 6 + bounce,
          child: child!,
        );
      },
      child: IgnorePointer(
        child: Icon(
          Icons.touch_app_rounded,
          color: Colors.white,
          size: 40,
          shadows: [
            Shadow(color: AppColors.black.withAlpha(160), blurRadius: 8),
          ],
        ),
      ),
    );
  }

  /// Card goes on whichever side of the spotlight has more room
  Widget _positionCard(
    BuildContext context,
    TutorialStep step,
    Rect? hole,
    Size size,
  ) {
    final card = _CoachCard(step: step);
    if (hole == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(20), child: card));
    }

    final spaceAbove = hole.top;
    final spaceBelow = size.height - hole.bottom;
    const gap = 14.0;
    // A bouncing finger sits under small targets - leave it room
    final pointerRoom = step.requiresAction && hole.shortestSide < 140 ? 44.0 : 0.0;

    if (spaceBelow >= spaceAbove) {
      return Positioned(
        left: 16,
        right: 16,
        top: min(hole.bottom + gap + pointerRoom, size.height - 120),
        child: card,
      );
    }
    return Positioned(
      left: 16,
      right: 16,
      bottom: min(size.height - hole.top + gap, size.height - 120),
      child: card,
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.step});

  final TutorialStep step;

  @override
  Widget build(BuildContext context) {
    final tutorial = context.read<TutorialCubit>();
    final game = context.read<GameCubit>().state;
    final (title, body) = _copy(step, game, tutorial.exampleWord);
    final accent = step.requiresAction ? AppColors.accentGold : AppColors.accentCyan;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withAlpha(250),
              AppColors.primaryDarkPurple.withAlpha(250),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 2),
          boxShadow: [
            BoxShadow(color: accent.withAlpha(90), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.orbitron(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.exo2(
                color: Colors.white.withAlpha(225),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: tutorial.dismiss,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(
                    'SKIP TUTORIAL',
                    style: GoogleFonts.exo2(
                      color: Colors.white.withAlpha(130),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (step == TutorialStep.drag) ...[
                  _CardButton(label: 'SHOW ME', filled: false, onTap: tutorial.showMe),
                  const SizedBox(width: 8),
                ],
                if (step.requiresAction)
                  _TryItBadge(label: _actionPrompt(step))
                else
                  _CardButton(
                    label: step == TutorialStep.welcome ? "LET'S GO" : 'GOT IT',
                    filled: true,
                    onTap: tutorial.next,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _actionPrompt(TutorialStep step) => switch (step) {
        TutorialStep.spinWheel => 'TAP THE WHEEL',
        TutorialStep.drag => 'YOUR TURN',
        TutorialStep.submit => 'TAP GO',
        TutorialStep.hint => 'TAP ?',
        _ => 'TRY IT',
      };

  static (String, String) _copy(TutorialStep step, GameState game, String? example) {
    final letter = game.currentLetter ?? '?';
    final word = example ?? '';
    return switch (step) {
      TutorialStep.welcome => (
          'WELCOME TO PRACTICE',
          'This round plays exactly like Alpha Quest. We\'ll pause the clock '
              'to show you each button as you need it.',
        ),
      TutorialStep.spinWheel => (
          'SPIN FOR A LETTER',
          'Every round starts here. Tap the wheel - every answer this round '
              'will start with the letter it lands on.',
        ),
      TutorialStep.previewWords => (
          'DID YOU CATCH THAT?',
          'As each category begins, the stars of a few real answers shimmer '
              'in order - then vanish. Quick eyes get a free hint!',
        ),
      TutorialStep.startLetter => (
          'YOUR LETTER',
          'Every answer must start with $letter. Its star glows cyan on the board.',
        ),
      TutorialStep.category => (
          'THE CATEGORY',
          'Name something in ${game.category}. Clear 5 categories to finish '
              'the letter.',
        ),
      TutorialStep.timer => (
          'THE CLOCK',
          'Time is held while we teach. Normally it keeps ticking: wrong '
              'answers cost 5s, while spaces and one-swipe words earn time back.',
        ),
      TutorialStep.drag => (
          'CONNECT THE STARS',
          'Drag across the stars to spell $word. Rest on each star until its '
              'ring fills. Spell it in one swipe for a +10s bonus!',
        ),
      TutorialStep.submit => (
          'SUBMIT',
          'Happy with your word? Tap GO to check it.',
        ),
      TutorialStep.wrongAnswer => (
          'NOT QUITE',
          'That one cost 5 seconds. Tap DEL to clear letters, then try again.',
        ),
      TutorialStep.space => (
          'TWO-WORD ANSWERS',
          'Spell the first word, tap ␣, then spell the next - like $word. '
              'Every space earns +10s.',
        ),
      TutorialStep.doubleLetters => (
          'DOUBLE LETTERS',
          'You can\'t drag onto the same star twice in a row. Tap x2 to repeat '
              'the last letter - $word needs it twice!',
        ),
      TutorialStep.hint => (
          'NEED A HINT?',
          'Tap ? to light up a real answer while every other star fades. It '
              'costs 10s - and it pulses whenever you look stuck.',
        ),
      TutorialStep.mysteryOrb => (
          'MYSTERY ORBS',
          'The glowing orb is a wildcard - it can be any letter. Using it '
              'triggers a surprise: usually a bonus, sometimes a penalty!',
        ),
      TutorialStep.skip => (
          'SKIP WITH A STAR',
          'Really stuck? Spend a star to skip a category. You earn a star '
              'for every 300 points.',
        ),
      TutorialStep.pause => (
          'PAUSE',
          'Need a break? Pause stops the clock and hides the board - no '
              'peeking. You can restart or quit from there too.',
        ),
    };
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.instance.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: filled
              ? const LinearGradient(colors: [AppColors.accentCyan, AppColors.accentPurple])
              : null,
          border: filled ? null : Border.all(color: Colors.white.withAlpha(140), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// "Do it now" label for action steps - the spotlight is the button
class _TryItBadge extends StatelessWidget {
  const _TryItBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGold.withAlpha(160)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, color: AppColors.accentGold, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: AppColors.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dim layer with a rounded cut-out and a breathing ring around it
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.pulse, required this.color});

  final Rect? hole;
  final double pulse;
  final Color color;

  static RRect _shape(Rect rect) {
    // Round targets (buttons, badges) get a circle; big areas a soft rectangle
    final isRoundish =
        rect.shortestSide < 120 && rect.longestSide / rect.shortestSide < 1.35;
    final radius = isRoundish ? rect.shortestSide / 2 : 20.0;
    return RRect.fromRectAndRadius(rect, Radius.circular(radius));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = AppColors.black.withAlpha(185);
    final hole = this.hole;
    if (hole == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }

    final shape = _shape(hole);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(shape),
      dim,
    );

    // Steady ring + an expanding echo
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
    );
    final echo = _shape(hole.inflate(4 + pulse * 14));
    canvas.drawRRect(
      echo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withAlpha(((1 - pulse) * 180).round()),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.pulse != pulse || old.color != color;
}

/// Swallows every touch except those inside [hole] when [passThrough]
class _Barrier extends SingleChildRenderObjectWidget {
  const _Barrier({required this.hole, required this.passThrough, super.child});

  final Rect? hole;
  final bool passThrough;

  @override
  _RenderBarrier createRenderObject(BuildContext context) =>
      _RenderBarrier(hole: hole, passThrough: passThrough);

  @override
  void updateRenderObject(BuildContext context, _RenderBarrier renderObject) {
    renderObject
      ..hole = hole
      ..passThrough = passThrough;
  }
}

class _RenderBarrier extends RenderProxyBox {
  _RenderBarrier({required this.hole, required this.passThrough});

  Rect? hole;
  bool passThrough;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    final hole = this.hole;
    // Let the touch fall through to the real game widget underneath
    if (passThrough && hole != null && hole.contains(position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
