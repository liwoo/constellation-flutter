import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/word_display_area.dart';
import 'package:constellation_app/game/widgets/letter_constellation.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// {@template game_body}
/// Body of the GamePage.
///
/// Game screen with timer, word count, category, word display, and letter constellation
/// {@endtemplate}
class GameBody extends StatelessWidget {
  /// {@macro game_body}
  const GameBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        return GradientBackground(
          child: Stack(
            children: [
              // Star decorations
              const Positioned.fill(
                child: StarDecoration(starCount: 100, starSize: 2),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    _buildTopBar(context, state),

                    const SizedBox(height: AppSpacing.md),

                    // Category banner
                    CategoryBanner(
                      category: state.category,
                      starCount: state.difficulty,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Word display area
                    WordDisplayArea(
                      selectedLetters: state.selectedLetters,
                    ),

                    const SizedBox(height: AppSpacing.lg),

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
                          onDragStart: (pos) {
                            context.read<GameCubit>().startDrag(pos);
                          },
                          onDragUpdate: (pos) {
                            context.read<GameCubit>().updateDrag(pos);
                          },
                          onDragEnd: () {
                            context.read<GameCubit>().endDrag();
                          },
                        ),
                      ),
                    ),

                    // GO and DEL action buttons
                    _buildActionButtons(context, state),

                    // Score display
                    _buildScoreDisplay(context, state),

                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: VS + Word count
          Row(
            children: [
              // VS text
              Text(
                'VS.',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Word count badge with label
              Column(
                children: [
                  BadgeWidget(
                    text: '${state.completedWords.length}',
                    backgroundColor: AppColors.accentGold,
                    textColor: AppColors.black,
                    size: 45,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'WORDS',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right side: Clock + Timer
          Row(
            children: [
              Column(
                children: [
                  Text(
                    'CLOCK',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  BadgeWidget(
                    text: '${state.timeRemaining}',
                    backgroundColor: AppColors.accentOrange,
                    textColor: AppColors.white,
                    size: 45,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GameState state) {
    final hasSelection = state.selectedLetterIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // DEL button (left side)
          GestureDetector(
            onTap: hasSelection
                ? () => context.read<GameCubit>().clearSelection()
                : null,
            child: ActionBubble(
              label: 'DEL',
              isSubmit: false,
              isActive: hasSelection,
              size: 65,
            ),
          ),

          // GO button (right side)
          GestureDetector(
            onTap: hasSelection
                ? () => context.read<GameCubit>().submitWord()
                : null,
            child: ActionBubble(
              label: 'GO',
              isSubmit: true,
              isActive: hasSelection,
              size: 65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SCORE: ',
            style: TextStyle(
              color: AppColors.white.withAlpha(180),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${state.score}',
            style: const TextStyle(
              color: AppColors.accentGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
