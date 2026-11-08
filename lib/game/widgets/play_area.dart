import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/letter_constellation.dart';
import 'package:constellation_app/game/widgets/word_display_area.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// Where a word gets built: the word so far, the constellation, and the
/// DEL / space / x2 / hint / GO buttons. Shared by Alpha Quest and match
/// play; drives the [GameCubit] above it.
class PlayArea extends StatelessWidget {
  const PlayArea({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GameCubit>();
    return Column(
      children: [
        // Word display area
        WordDisplayArea(
          selectedLetters: state.selectedLetters,
          letters: state.letters,
          committedWord: state.committedWord,
          celebrate: state.lastAnswerCorrect == true,
          shake: state.lastAnswerCorrect == false,
          pendingLetterId: state.pendingLetterId,
          letterDwellStartTime: state.letterDwellStartTime,
          onRemoveLetterAt: cubit.removeLetterAt,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Letter constellation
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: LetterConstellation(
              letters: state.letters,
              selectedLetterIds: state.selectedLetterIds,
              currentDragPosition: state.currentDragPosition,
              isDragging: state.isDragging,
              startingLetter: state.currentLetter,
              hintLetterIds: state.hintLetterIds,
              hintAnimationIndex: state.hintAnimationIndex,
              approachingLetterIds: state.approachingLetterIds,
              // Mystery orb state
              mysteryOrbs: state.mysteryOrbs,
              pendingMysteryOrbId: state.pendingMysteryOrbId,
              mysteryOrbDwellStartTime: state.mysteryOrbDwellStartTime,
              // Letter dwell progress
              pendingLetterId: state.pendingLetterId,
              letterDwellStartTime: state.letterDwellStartTime,
              lastConnectedLetterId: state.lastConnectedLetterId,
              // Pure connection celebration
              showConnectionAnimation: state.showConnectionAnimation,
              // A few answers shimmer across the stars as the category begins
              shimmerPaths: state.previewPaths,
              shimmerPaused: state.isPaused,
              shootingStar: state.shootingStar,
              onDragStart: cubit.startDrag,
              onDragUpdate: cubit.updateDrag,
              onDragEnd: cubit.endDrag,
            ),
          ),
        ),

        // DEL and GO buttons at the bottom
        WordActionBar(state: state),
      ],
    );
  }
}

/// DEL, space, x2, hint and GO
class WordActionBar extends StatelessWidget {
  const WordActionBar({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final hasSelection = state.selectedLetterIds.isNotEmpty;
    final hasContent = state.hasWordContent; // Either committed or selected
    // Can add space only if we have current selection (not just committed)
    final canAddSpace = hasSelection;
    // Can repeat only if we have current selection
    final canRepeat = hasSelection;
    // Can use hint if hints remaining, no hint currently showing, and enough time (15s+)
    final canUseHint = state.hintsRemaining > 0 &&
        state.hintWord == null &&
        state.timeRemaining >= 15;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // DEL button - clears everything
          GestureDetector(
            onTap: hasContent
                ? () => context.read<GameCubit>().clearSelection()
                : null,
            child: ActionBubble(
              label: 'DEL',
              isSubmit: false,
              isActive: hasContent,
              size: 44,
            ),
          ),

          // SPACE button - commits current selection and allows fresh drag
          GestureDetector(
            onTap: canAddSpace
                ? () => context.read<GameCubit>().insertSpace()
                : null,
            child: ActionBubble(
              label: '␣',
              isSubmit: false,
              isBonus: true,
              isActive: canAddSpace,
              size: 44,
              badgeCount: state.spaceUsageCount,
            ),
          ),

          // x2 button (repeat last letter for doubles like SS)
          GestureDetector(
            onTap: canRepeat
                ? () => context.read<GameCubit>().repeatLastLetter()
                : null,
            child: ActionBubble(
              label: 'x2',
              isSubmit: false,
              isBonus: true,
              isActive: canRepeat,
              size: 44,
              badgeCount: state.repeatUsageCount,
            ),
          ),

          // HINT button - shows a valid word
          GestureDetector(
            onTap: canUseHint
                ? () => context.read<GameCubit>().useHint()
                : null,
            // Breathes when the player looks stuck
            child: AttentionPulse(
              active: canUseHint && state.isStuck,
              child: ActionBubble(
                label: '?',
                isSubmit: false,
                isHint: true,
                isActive: canUseHint,
                size: 44,
                badgeCount: state.hintsRemaining,
              ),
            ),
          ),

          // GO button - submits full word (committed + selection)
          GestureDetector(
            onTap: hasContent
                ? () => context.read<GameCubit>().submitWord()
                : null,
            child: ActionBubble(
              label: 'GO',
              isSubmit: true,
              isActive: hasContent,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }
}
