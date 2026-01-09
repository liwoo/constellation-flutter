import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/game/cubit/alpha_quest_cubit.dart';
import 'package:constellation_app/game/widgets/spinning_wheel.dart';
import 'package:constellation_app/game/widgets/category_jackpot.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// {@template alpha_quest_body}
/// Body of the Alpha Quest game mode.
/// {@endtemplate}
class AlphaQuestBody extends StatefulWidget {
  /// {@macro alpha_quest_body}
  const AlphaQuestBody({super.key});

  @override
  State<AlphaQuestBody> createState() => _AlphaQuestBodyState();
}

class _AlphaQuestBodyState extends State<AlphaQuestBody> {
  final _wordController = TextEditingController();
  bool _showWheel = true;
  bool _showCategoryJackpot = false;

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  void _onLetterSelected(String letter) {
    setState(() {
      _showWheel = false;
      _showCategoryJackpot = true;
    });
    context.read<AlphaQuestCubit>().selectLetter(letter);
  }

  void _onCategorySelected() {
    setState(() {
      _showCategoryJackpot = false;
    });
  }

  void _submitWord() {
    if (_wordController.text.isEmpty) return;
    context.read<AlphaQuestCubit>().submitWord(_wordController.text);
    _wordController.clear();
  }

  void _prepareNextRound() {
    setState(() {
      _showWheel = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AlphaQuestCubit, AlphaQuestState>(
      listener: (context, state) {
        // Handle answer feedback
        if (state.lastAnswerCorrect == true && state.currentLetter == null) {
          // Correct answer - prepare for next round
          _prepareNextRound();
        }
      },
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

                    // Progress indicator (completed letters)
                    _buildProgressIndicator(state),

                    const SizedBox(height: AppSpacing.lg),

                    // Main game area
                    Expanded(
                      child: _buildGameArea(context, state),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),

              // Game Over overlay
              if (state.isGameOver) _buildGameOverOverlay(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, AlphaQuestState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Completed count
          Column(
            children: [
              _buildCoinBadge(
                text: '${state.completedLetters.length}/26',
                backgroundColor: AppColors.accentGold,
                textColor: AppColors.black,
                size: 52,
              ),
              const SizedBox(height: 4),
              const Text(
                'LETTERS',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Center: Score
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

          // Right: Timer
          Column(
            children: [
              _buildCoinBadge(
                text: '${state.timeRemaining}',
                backgroundColor: state.timeRemaining <= 30
                    ? AppColors.accentPink
                    : AppColors.accentOrange,
                textColor: AppColors.white,
                size: 52,
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
    double size = 52,
  }) {
    final HSLColor hsl = HSLColor.fromColor(backgroundColor);
    final Color highlightColor =
        hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    final Color shadowColor =
        hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
    final Color darkShadow =
        hsl.withLightness((hsl.lightness - 0.35).clamp(0.0, 1.0)).toColor();

    return Container(
      width: size,
      height: size,
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
            colors: [highlightColor, backgroundColor, shadowColor],
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(AlphaQuestState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.white.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          // Letter bubbles (small)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(26, (index) {
              final letter = String.fromCharCode('A'.codeUnitAt(0) + index);
              final isCompleted = state.completedLetters.contains(letter);
              final isCurrent = letter == state.currentLetter;

              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.accentGold
                      : isCurrent
                          ? AppColors.accentPink
                          : Colors.white.withAlpha(50),
                  border: isCurrent
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: isCompleted || isCurrent
                          ? AppColors.black
                          : Colors.white.withAlpha(150),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea(BuildContext context, AlphaQuestState state) {
    if (!state.isPlaying && !state.isGameOver) {
      // Start screen
      return _buildStartScreen(context);
    }

    if (_showWheel) {
      // Show spinning wheel
      return _buildWheelScreen(context, state);
    }

    if (_showCategoryJackpot && state.currentCategory != null) {
      // Show category jackpot
      return Center(
        child: CategoryJackpot(
          targetCategory: state.currentCategory!,
          onComplete: _onCategorySelected,
        ),
      );
    }

    // Show word input
    return _buildWordInputScreen(context, state);
  }

  Widget _buildStartScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ALPHA QUEST',
            style: TextStyle(
              color: AppColors.accentGold,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete all 26 letters\nbefore time runs out!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () {
              context.read<AlphaQuestCubit>().startGame();
            },
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
              child: const Text(
                'START',
                style: TextStyle(
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

  Widget _buildWheelScreen(BuildContext context, AlphaQuestState state) {
    final remainingLetters = <String>[];
    for (var i = 0; i < 26; i++) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
      if (!state.completedLetters.contains(letter)) {
        remainingLetters.add(letter);
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SPIN FOR YOUR LETTER',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          SpinningWheel(
            letters: remainingLetters,
            onLetterSelected: _onLetterSelected,
            size: 280,
          ),
        ],
      ),
    );
  }

  Widget _buildWordInputScreen(BuildContext context, AlphaQuestState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current letter badge
          if (state.currentLetter != null) ...[
            _buildStarLetterBadge(state.currentLetter!),
            const SizedBox(height: 24),
          ],

          // Category display
          if (state.currentCategory != null) ...[
            CategoryBanner(category: state.currentCategory!),
            const SizedBox(height: 24),
          ],

          // Feedback message
          if (state.lastAnswerCorrect != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: state.lastAnswerCorrect!
                    ? Colors.green.withAlpha(100)
                    : Colors.red.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.lastAnswerCorrect!
                    ? 'Correct! +${state.score} points'
                    : 'Wrong! Try another word (-5s)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Word input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha(50),
                width: 2,
              ),
            ),
            child: TextField(
              controller: _wordController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter a ${state.currentCategory} starting with ${state.currentLetter}',
                hintStyle: TextStyle(
                  color: Colors.white.withAlpha(100),
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _submitWord(),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          GestureDetector(
            onTap: _submitWord,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withAlpha(100),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Text(
                'SUBMIT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
              style: const TextStyle(
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

  Widget _buildGameOverOverlay(BuildContext context, AlphaQuestState state) {
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
                style: TextStyle(
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
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${state.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Letters: ${state.completedLetters.length}/26',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  context.read<AlphaQuestCubit>().resetGame();
                  setState(() {
                    _showWheel = true;
                  });
                },
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
                  child: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 20,
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
}
