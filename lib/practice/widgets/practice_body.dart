import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/game/widgets/letter_constellation.dart';
import 'package:constellation_app/practice/cubit/cubit.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// {@template practice_body}
/// Practice lessons: one mechanic at a time on a tiny board, with a
/// one-line cue for the next move and the right button pulsing.
/// {@endtemplate}
class PracticeBody extends StatelessWidget {
  /// {@macro practice_body}
  const PracticeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PracticeCubit, PracticeState>(
      builder: (context, state) {
        return GradientBackground(
          child: Stack(
            children: [
              const Positioned.fill(
                child: StarDecoration(starCount: 100, starSize: 2),
              ),
              SafeArea(child: _buildLesson(context, state)),
              if (state.phase == PracticePhase.lessonComplete)
                const _LessonCompleteBurst(),
              if (state.phase == PracticePhase.finished)
                _buildFinished(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLesson(BuildContext context, PracticeState state) {
    final cubit = context.read<PracticeCubit>();
    return Column(
      children: [
        _buildTopBar(context, state),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'LESSON ${state.lessonIndex + 1} OF ${practiceLessons.length}',
          style: GoogleFonts.exo2(
            color: Colors.white.withAlpha(150),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          state.lesson.title,
          style: GoogleFonts.orbitron(
            color: AppColors.accentGold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            state.lesson.goal,
            textAlign: TextAlign.center,
            style: GoogleFonts.exo2(
              color: Colors.white.withAlpha(210),
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _TargetWord(state: state),
        const SizedBox(height: AppSpacing.md),
        _buildCue(context, state),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: LetterConstellation(
              letters: state.letters,
              selectedLetterIds: state.selectedLetterIds,
              currentDragPosition: state.currentDragPosition,
              isDragging: state.isDragging,
              // The star to reach next glows
              startingLetter: state.nextLetter,
              hintLetterIds: state.guideIds,
              hintAnimationIndex: state.guideIndex,
              approachingLetterIds: state.approachingLetterIds,
              pendingLetterId: state.pendingLetterId,
              letterDwellStartTime: state.letterDwellStartTime,
              lastConnectedLetterId: state.lastConnectedLetterId,
              onDragStart: cubit.startDrag,
              onDragUpdate: cubit.updateDrag,
              onDragEnd: cubit.endDrag,
            ),
          ),
        ),
        _buildButtons(context, state),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, PracticeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDarkPurple.withAlpha(200),
                border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'PRACTICE',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          // Lesson progress dots
          Row(
            children: [
              for (var i = 0; i < practiceLessons.length; i++)
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < state.lessonIndex ||
                            (i == state.lessonIndex && state.phase != PracticePhase.playing)
                        ? AppColors.accentGold
                        : i == state.lessonIndex
                            ? Colors.white
                            : Colors.white.withAlpha(60),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// One line telling the player exactly what to do next
  Widget _buildCue(BuildContext context, PracticeState state) {
    final next = state.nextLetter;
    final last = state.currentSelection.isEmpty
        ? ''
        : state.currentSelection[state.currentSelection.length - 1];

    var (icon, text) = switch (state.cue) {
      PracticeCue.touchStar => (
          Icons.touch_app_rounded,
          state.committedWord.isEmpty ? 'Touch $next to start' : 'Touch $next to start the next word',
        ),
      PracticeCue.slideAndHold => (Icons.swipe_rounded, 'Slide to $next and hold until it clicks'),
      PracticeCue.space => (Icons.space_bar_rounded, 'Tap ␣ to add a space'),
      PracticeCue.repeat => (Icons.repeat_rounded, 'Tap x2 to repeat $last'),
      PracticeCue.go => (Icons.check_circle_rounded, 'Tap GO!'),
      PracticeCue.delete => (Icons.backspace_rounded, 'Wrong star - tap DEL to clear'),
    };
    if (state.releasedEarly && state.cue == PracticeCue.slideAndHold) {
      (icon, text) = (Icons.timelapse_rounded, 'Almost! Hold on $next until the ring fills and clicks');
    } else if (state.submittedTooSoon && state.cue != PracticeCue.delete) {
      text = 'Not finished yet - ${text[0].toLowerCase()}${text.substring(1)}';
    }

    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Row(
                key: ValueKey(text),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.accentCyan, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 2,
                      style: GoogleFonts.exo2(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: context.read<PracticeCubit>().showMe,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(110)),
              ),
              child: Text(
                'SHOW ME',
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(200),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, PracticeState state) {
    final cubit = context.read<PracticeCubit>();
    final hasSelection = state.selectedLetterIds.isNotEmpty;
    final cue = state.cue;

    Widget button({
      required String label,
      required bool active,
      required bool pulse,
      required VoidCallback onTap,
      bool isSubmit = false,
      bool isBonus = false,
    }) {
      final color = isSubmit
          ? const Color(0xFF4CAF50)
          : isBonus
              ? AppColors.accentGold
              : const Color(0xFFE91E63);
      // The button to press pulses; the others step back (but still work)
      return GestureDetector(
        onTap: active ? onTap : null,
        child: AnimatedOpacity(
          opacity: !active || pulse ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: AttentionPulse(
            active: active && pulse,
            color: color,
            child: ActionBubble(
              label: label,
              isSubmit: isSubmit,
              isBonus: isBonus,
              isActive: active,
              size: 52,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          button(
            label: 'DEL',
            active: state.hasWordContent,
            pulse: cue == PracticeCue.delete,
            onTap: cubit.clearSelection,
          ),
          button(
            label: '␣',
            active: hasSelection,
            pulse: cue == PracticeCue.space,
            onTap: cubit.insertSpace,
            isBonus: true,
          ),
          button(
            label: 'x2',
            active: hasSelection,
            pulse: cue == PracticeCue.repeat,
            onTap: cubit.repeatLastLetter,
            isBonus: true,
          ),
          button(
            label: 'GO',
            active: state.hasWordContent,
            pulse: cue == PracticeCue.go,
            onTap: cubit.submit,
            isSubmit: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinished(BuildContext context) {
    final skills = [
      'Connect stars by sliding',
      'Hold for the click',
      '␣ for two-word answers',
      'x2 for double letters',
    ];

    return Container(
      color: AppColors.black.withAlpha(200),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPurple.withAlpha(240),
                AppColors.primaryDarkPurple.withAlpha(240),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accentGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withAlpha(100),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, color: AppColors.accentGold, size: 56),
              const SizedBox(height: 12),
              Text(
                "YOU'VE GOT\nTHE MOVES!",
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: AppColors.accentGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              for (final skill in skills)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        skill,
                        style: GoogleFonts.exo2(color: Colors.white.withAlpha(220), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/game'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGold, AppColors.accentOrange],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'PLAY ALPHA QUEST',
                    style: GoogleFonts.orbitron(
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  AudioService.instance.play(GameSound.buttonTap);
                  context.read<PracticeCubit>().restart();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withAlpha(150), width: 2),
                  ),
                  child: Text(
                    'PRACTICE AGAIN',
                    style: GoogleFonts.orbitron(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  'Back to Menu',
                  style: GoogleFonts.exo2(color: Colors.white.withAlpha(150), fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The word to spell: filled slots for what's done, the next one ringed.
/// While a star is being held, its letter fills the slot it will land in
/// with the same dwell ring as the game's word area.
class _TargetWord extends StatelessWidget {
  const _TargetWord({required this.state});

  final PracticeState state;

  static const double _slotSize = 36;

  @override
  Widget build(BuildContext context) {
    final target = state.targetWord;
    final built = state.builtWord;
    // Only letters that actually match count as done
    var done = 0;
    while (done < built.length && done < target.length && built[done] == target[done]) {
      done++;
    }
    final next = state.isOnTrack ? done : -1;
    final solved = state.phase != PracticePhase.playing;

    // Star being held right now, and the slot it would land in
    final pendingId = state.pendingLetterId;
    final pending = pendingId == null
        ? null
        : state.letters.where((l) => l.id == pendingId).firstOrNull?.letter;
    final landing = pending != null && !solved && built.length < target.length
        ? built.length
        : -1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < target.length; i++)
          if (target[i] == ' ')
            const SizedBox(width: 16)
          else if (i == landing)
            _pendingSlot(pending!, correct: pending == target[i])
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _slotSize,
              height: _slotSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: solved
                    ? const Color(0xFF4CAF50)
                    : i < done
                        ? AppColors.accentGold
                        : Colors.white.withAlpha(25),
                border: Border.all(
                  color: i == next && !solved
                      ? AppColors.accentCyan
                      : Colors.white.withAlpha(i < done || solved ? 0 : 70),
                  width: i == next && !solved ? 2.5 : 1.5,
                ),
              ),
              child: Text(
                target[i],
                style: GoogleFonts.orbitron(
                  color: i < done || solved ? AppColors.black : Colors.white.withAlpha(110),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      ],
    );
  }

  /// The held star's letter in its landing slot, ringed as the dwell fills.
  /// Pink when it's the wrong star for this slot.
  Widget _pendingSlot(String letter, {required bool correct}) {
    final color = correct ? AppColors.accentCyan : AppColors.accentPink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: DwellProgress(
        dwellStartTime: state.letterDwellStartTime,
        builder: (context, progress) => SizedBox(
          width: _slotSize,
          height: _slotSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -6,
                top: -6,
                right: -6,
                bottom: -6,
                child: CustomPaint(
                  painter: DwellRingPainter(progress: progress, color: color),
                ),
              ),
              Container(
                width: _slotSize,
                height: _slotSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryDarkPurple,
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha((progress * 200).toInt()),
                      blurRadius: 10 + progress * 8,
                      spreadRadius: 1 + progress * 3,
                    ),
                  ],
                ),
                child: Text(
                  letter,
                  style: GoogleFonts.orbitron(
                    color: Colors.white.withAlpha((140 + progress * 115).toInt()),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick "nice!" between lessons
class _LessonCompleteBurst extends StatelessWidget {
  const _LessonCompleteBurst();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGold, AppColors.accentOrange],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withAlpha(150),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: AppColors.black, size: 60),
              ),
              const SizedBox(height: 12),
              Text(
                'NICE!',
                style: GoogleFonts.orbitron(
                  color: AppColors.accentGold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  shadows: [Shadow(color: AppColors.black.withAlpha(150), blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
