import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/word_display_area.dart';
import 'package:constellation_app/game/widgets/letter_constellation.dart';
import 'package:constellation_app/game/widgets/spinning_wheel.dart';
import 'package:constellation_app/game/widgets/category_jackpot.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/services/services.dart';

/// {@template game_body}
/// Body of the GamePage - Alpha Quest game mode.
/// {@endtemplate}
class GameBody extends StatelessWidget {
  /// {@macro game_body}
  const GameBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listenWhen: (previous, current) =>
          previous.lastAnswerCorrect != current.lastAnswerCorrect &&
          current.lastAnswerCorrect != null,
      listener: (context, state) {
        _showFeedbackToast(context, state.lastAnswerCorrect!);
      },
      child: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) {
          return GradientBackground(
            child: Stack(
              children: [
                // Star decorations
                const Positioned.fill(
                  child: StarDecoration(starCount: 100, starSize: 2),
                ),

                // Main content based on game phase
                SafeArea(
                  child: _buildPhaseContent(context, state),
                ),

                // Game Over overlay
                if (state.phase == GamePhase.gameOver)
                  _buildGameOverOverlay(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFeedbackToast(BuildContext context, bool isCorrect) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isCorrect ? 'Correct!' : 'Wrong! (-5s)',
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: isCorrect
            ? Colors.green.withAlpha(220)
            : Colors.red.withAlpha(220),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(
          bottom: 100,
          left: 50,
          right: 50,
        ),
        duration: const Duration(milliseconds: 1200),
        dismissDirection: DismissDirection.none,
      ),
    );
  }

  Widget _buildPhaseContent(BuildContext context, GameState state) {
    switch (state.phase) {
      case GamePhase.notStarted:
        return _buildStartScreen(context);
      case GamePhase.spinningWheel:
        return _buildWheelScreen(context, state);
      case GamePhase.categoryReveal:
        return _buildCategoryRevealScreen(context, state);
      case GamePhase.playingRound:
        return _buildPlayingScreen(context, state);
      case GamePhase.gameOver:
        return _buildPlayingScreen(context, state); // Show behind overlay
    }
  }

  Widget _buildStartScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ALPHA QUEST',
            style: GoogleFonts.orbitron(
              color: AppColors.accentGold,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete all 25 letters\nTime carries over - bonus for x2 & spaces!',
            textAlign: TextAlign.center,
            style: GoogleFonts.exo2(
              color: Colors.white.withAlpha(200),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () => context.read<GameCubit>().startGame(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentGold, AppColors.accentOrange],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withAlpha(100),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                'START',
                style: GoogleFonts.orbitron(
                  color: AppColors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelScreen(BuildContext context, GameState state) {
    // Use weighted letters - easier letters more likely early in game
    final remainingLetters = context.read<GameCubit>().getWeightedRemainingLetters();

    return Column(
      children: [
        _buildTopBar(context, state),
        const SizedBox(height: AppSpacing.md),
        _buildProgressIndicator(state),
        const Spacer(),
        Text(
          'SPIN FOR YOUR LETTER',
          style: GoogleFonts.exo2(
            color: Colors.white.withAlpha(200),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        SpinningWheel(
          letters: remainingLetters,
          onLetterSelected: (letter) {
            context.read<GameCubit>().onWheelLanded(letter);
          },
          size: 280,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildCategoryRevealScreen(BuildContext context, GameState state) {
    return Column(
      children: [
        _buildTopBar(context, state),
        const SizedBox(height: AppSpacing.md),
        _buildProgressIndicator(state),
        const Spacer(),
        // Show current letter
        _buildStarLetterBadge(state.currentLetter ?? '?'),
        const SizedBox(height: 32),
        // Category jackpot
        CategoryJackpot(
          targetCategory: state.category,
          onComplete: () {
            context.read<GameCubit>().onCategoryRevealed();
          },
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildPlayingScreen(BuildContext context, GameState state) {
    return Column(
      children: [
        // Top bar
        _buildTopBar(context, state),

        const SizedBox(height: AppSpacing.sm),

        // Progress indicator
        _buildProgressIndicator(state),

        const SizedBox(height: AppSpacing.sm),

        // Current letter badge, category, and progress
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.currentLetter != null) ...[
              _buildSmallLetterBadge(state.currentLetter!),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: CategoryBanner(category: state.category),
            ),
            const SizedBox(width: 8),
            // Category progress indicator (1/5, 2/5, etc.)
            _buildCategoryProgress(state),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Word display area
        WordDisplayArea(
          selectedLetters: state.selectedLetters,
          committedWord: state.committedWord,
          celebrate: state.lastAnswerCorrect == true,
          shake: state.lastAnswerCorrect == false,
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

        // DEL and GO buttons at the bottom
        _buildActionButtons(context, state),

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildCategoryProgress(GameState state) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryPurple.withAlpha(200),
        border: Border.all(
          color: AppColors.accentGold.withAlpha(150),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${state.categoryIndex + 1}/${GameState.categoriesPerLetter}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStarLetterBadge(String letter) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withAlpha(150),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // Badge
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentGold,
                AppColors.accentOrange,
              ],
            ),
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withAlpha(100),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: GoogleFonts.orbitron(
                color: AppColors.black,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallLetterBadge(String letter) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGold,
            AppColors.accentOrange,
          ],
        ),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withAlpha(100),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.orbitron(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.white.withAlpha(50),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
          minHeight: 6,
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Completed letters count
          Column(
            children: [
              _buildCoinBadge(
                text: '${state.completedLetters.length}',
                backgroundColor: AppColors.accentGold,
                textColor: AppColors.black,
              ),
              const SizedBox(height: 4),
              const Text(
                'DONE',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Center: Score display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.accentGold,
                  AppColors.accentOrange,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCORE',
                  style: TextStyle(
                    color: AppColors.black.withAlpha(150),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${state.score}',
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Right side: Timer badge
          Column(
            children: [
              _buildCoinBadge(
                text: '${state.timeRemaining}',
                backgroundColor: state.timeRemaining <= 30
                    ? AppColors.accentPink
                    : AppColors.accentOrange,
                textColor: AppColors.white,
              ),
              const SizedBox(height: 4),
              const Text(
                'TIME',
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
    );
  }

  Widget _buildCoinBadge({
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    final HSLColor hsl = HSLColor.fromColor(backgroundColor);
    final Color highlightColor = hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    final Color shadowColor = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
    final Color darkShadow = hsl.withLightness((hsl.lightness - 0.35).clamp(0.0, 1.0)).toColor();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: darkShadow,
            blurRadius: 1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: AppColors.black.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              highlightColor,
              backgroundColor,
              shadowColor,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
          border: Border.all(
            color: darkShadow.withAlpha(150),
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 0.8,
              colors: [
                Colors.white.withAlpha(120),
                Colors.white.withAlpha(30),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(50),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GameState state) {
    final hasSelection = state.selectedLetterIds.isNotEmpty;
    final hasContent = state.hasWordContent; // Either committed or selected
    // Can add space only if we have current selection (not just committed)
    final canAddSpace = hasSelection;
    // Can repeat only if we have current selection
    final canRepeat = hasSelection;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // DEL button (left side) - clears everything
          GestureDetector(
            onTap: hasContent
                ? () => context.read<GameCubit>().clearSelection()
                : null,
            child: ActionBubble(
              label: 'DEL',
              isSubmit: false,
              isActive: hasContent,
              size: 55,
            ),
          ),

          // SPACE button - commits current selection and allows fresh drag
          // Bonus themed with usage count badge
          GestureDetector(
            onTap: canAddSpace
                ? () => context.read<GameCubit>().insertSpace()
                : null,
            child: ActionBubble(
              label: '␣',
              isSubmit: false,
              isBonus: true, // Gold bonus theme
              isActive: canAddSpace,
              size: 55,
              badgeCount: state.spaceUsageCount, // Show usage count
            ),
          ),

          // x2 button (repeat last letter for doubles like SS)
          // Bonus themed with usage count badge
          GestureDetector(
            onTap: canRepeat
                ? () => context.read<GameCubit>().repeatLastLetter()
                : null,
            child: ActionBubble(
              label: 'x2',
              isSubmit: false,
              isBonus: true, // Gold bonus theme
              isActive: canRepeat,
              size: 55,
              badgeCount: state.repeatUsageCount, // Show usage count
            ),
          ),

          // GO button (right side) - submits full word (committed + selection)
          GestureDetector(
            onTap: hasContent
                ? () => context.read<GameCubit>().submitWord()
                : null,
            child: ActionBubble(
              label: 'GO',
              isSubmit: true,
              isActive: hasContent,
              size: 55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, GameState state) {
    return Container(
      color: AppColors.black.withAlpha(200),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
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
            border: Border.all(
              color: state.isWinner
                  ? AppColors.accentGold
                  : AppColors.accentPink,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (state.isWinner
                    ? AppColors.accentGold
                    : AppColors.accentPink).withAlpha(100),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.isWinner ? 'VICTORY!' : 'TIME\'S UP!',
                style: GoogleFonts.orbitron(
                  color: state.isWinner
                      ? AppColors.accentGold
                      : AppColors.accentPink,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SCORE',
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(150),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${state.score}',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // High score comparison
              _buildHighScoreDisplay(state.score),
              const SizedBox(height: 16),
              Text(
                'Letters: ${state.completedLetters.length}/${GameState.totalLetters}',
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(200),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),
              // Try Again button
              GestureDetector(
                onTap: () => context.read<GameCubit>().resetGame(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGold, AppColors.accentOrange],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'TRY AGAIN',
                    style: GoogleFonts.orbitron(
                      color: AppColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Menu button
              GestureDetector(
                onTap: () => context.go('/'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withAlpha(150),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'MENU',
                    style: GoogleFonts.orbitron(
                      color: Colors.white.withAlpha(200),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighScoreDisplay(int currentScore) {
    return FutureBuilder<int>(
      future: StorageService.instance.getHighScore(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final highScore = snapshot.data!;
        final isNewHighScore = currentScore >= highScore && currentScore > 0;

        if (isNewHighScore) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGold, AppColors.accentOrange],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'NEW HIGH SCORE!',
                  style: GoogleFonts.orbitron(
                    color: AppColors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          );
        }

        if (highScore > 0) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'Best: $highScore',
                style: GoogleFonts.exo2(
                  color: AppColors.accentGold.withAlpha(200),
                  fontSize: 14,
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
