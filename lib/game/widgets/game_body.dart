import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/word_display_area.dart';
import 'package:constellation_app/game/widgets/letter_constellation.dart';
import 'package:constellation_app/game/widgets/spinning_wheel.dart';
import 'package:constellation_app/game/widgets/category_jackpot.dart';
import 'package:constellation_app/game/widgets/animated_counter.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/services/shake_detection_service.dart';

/// {@template game_body}
/// Body of the GamePage - Alpha Quest game mode.
/// {@endtemplate}
class GameBody extends StatefulWidget {
  /// {@macro game_body}
  const GameBody({super.key});

  @override
  State<GameBody> createState() => _GameBodyState();
}

class _GameBodyState extends State<GameBody>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Animation for floating time bonus
  late AnimationController _bonusAnimController;
  late Animation<double> _bonusOpacity;
  late Animation<double> _bonusOffset;
  late Animation<double> _bonusScale;
  int? _displayedBonus;

  // Animation for mystery outcome
  late AnimationController _mysteryAnimController;
  late Animation<double> _mysteryOpacity;
  late Animation<double> _mysteryScale;
  MysteryOutcome? _displayedMysteryOutcome;

  // High score tracking
  int _highScore = 0;

  @override
  void initState() {
    super.initState();

    // Register for app lifecycle events (background time tracking)
    WidgetsBinding.instance.addObserver(this);

    _bonusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bonusOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_bonusAnimController);

    _bonusOffset = Tween<double>(begin: 0, end: -80).animate(
      CurvedAnimation(parent: _bonusAnimController, curve: Curves.easeOut),
    );

    _bonusScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
    ]).animate(_bonusAnimController);

    // Mystery outcome animation
    _mysteryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _mysteryOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_mysteryAnimController);

    _mysteryScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
    ]).animate(_mysteryAnimController);

    // Set up shake detection for cheat code
    ShakeDetectionService.instance.onCheatDetected = _onShakeCheatDetected;
    ShakeDetectionService.instance.startListening();

    // Load high score for display
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final highScore = await StorageService.instance.getHighScore();
    if (mounted) {
      setState(() {
        _highScore = highScore;
      });
    }
  }

  void _onShakeCheatDetected() {
    if (!mounted) return;
    final cubit = context.read<GameCubit>();
    final success = cubit.skipCategoryCheat();
    if (success) {
      // Show visual feedback for cheat activation
      _showCheatActivated();
    }
  }

  void _showCheatActivated() {
    // Use the mystery outcome animation to show "SKIP!" feedback
    setState(() {
      _displayedMysteryOutcome = null; // Clear any existing
    });
    // Show a snackbar for feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Category skipped! +15s',
          style: GoogleFonts.exo2(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AppColors.accentGold,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 50, right: 50),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ShakeDetectionService.instance.stopListening();
    ShakeDetectionService.instance.onCheatDetected = null;
    _bonusAnimController.dispose();
    _mysteryAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Guard against accessing context when widget is not mounted
    if (!mounted) return;

    final cubit = context.read<GameCubit>();

    switch (state) {
      case AppLifecycleState.paused:
        // App went to background - record timestamp
        // Only 'paused' means true background (not 'inactive' which fires for
        // brief interruptions like notification panel or control center)
        cubit.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App returned to foreground - deduct elapsed time
        cubit.onAppResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // inactive: Brief interruption (notification panel, incoming call dialog)
        // hidden: App hidden but may return quickly
        // detached: App terminating
        // Don't track time for these - only true background (paused)
        break;
    }
  }

  void _showTimeBonus(int bonus) {
    setState(() {
      _displayedBonus = bonus;
    });
    _bonusAnimController.forward(from: 0);
  }

  void _showMysteryOutcome(MysteryOutcome outcome) {
    setState(() {
      _displayedMysteryOutcome = outcome;
    });
    _mysteryAnimController.forward(from: 0);
  }

  /// Get display text for mystery outcome
  String _getMysteryOutcomeText(MysteryOutcome outcome) {
    switch (outcome) {
      case MysteryOutcome.timeBonus:
        return '+10s';
      case MysteryOutcome.scoreMultiplier:
        return '1.5x NEXT';
      case MysteryOutcome.freeHint:
        return '+1 HINT';
      case MysteryOutcome.timePenalty:
        return '-5s';
      case MysteryOutcome.scrambleLetters:
        return 'SCRAMBLE!';
    }
  }

  /// Get icon for mystery outcome
  IconData _getMysteryOutcomeIcon(MysteryOutcome outcome) {
    switch (outcome) {
      case MysteryOutcome.timeBonus:
        return Icons.timer;
      case MysteryOutcome.scoreMultiplier:
        return Icons.star;
      case MysteryOutcome.freeHint:
        return Icons.lightbulb;
      case MysteryOutcome.timePenalty:
        return Icons.timer_off;
      case MysteryOutcome.scrambleLetters:
        return Icons.shuffle;
    }
  }

  /// Check if outcome is a reward (vs penalty)
  bool _isRewardOutcome(MysteryOutcome outcome) {
    return outcome == MysteryOutcome.timeBonus ||
        outcome == MysteryOutcome.scoreMultiplier ||
        outcome == MysteryOutcome.freeHint;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GameCubit, GameState>(
          listenWhen: (previous, current) =>
              previous.lastTimeBonus != current.lastTimeBonus &&
              current.lastTimeBonus != null &&
              current.lastTimeBonus! > 0,
          listener: (context, state) {
            _showTimeBonus(state.lastTimeBonus!);
          },
        ),
        BlocListener<GameCubit, GameState>(
          listenWhen: (previous, current) =>
              previous.lastMysteryOutcome != current.lastMysteryOutcome &&
              current.lastMysteryOutcome != null,
          listener: (context, state) {
            _showMysteryOutcome(state.lastMysteryOutcome!);
          },
        ),
        // Reload high score when game ends (in case new record was set)
        BlocListener<GameCubit, GameState>(
          listenWhen: (previous, current) =>
              previous.phase != GamePhase.gameOver &&
              current.phase == GamePhase.gameOver,
          listener: (context, state) {
            _loadHighScore();
          },
        ),
      ],
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

                // Floating time bonus animation
                if (_displayedBonus != null)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _bonusAnimController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bonusOffset.value),
                          child: Opacity(
                            opacity: _bonusOpacity.value,
                            child: Transform.scale(
                              scale: _bonusScale.value,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.accentGold,
                                        AppColors.accentOrange,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentGold.withAlpha(150),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.timer,
                                        color: AppColors.black,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+${_displayedBonus}s',
                                        style: GoogleFonts.orbitron(
                                          color: AppColors.black,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Mystery outcome feedback overlay
                if (_displayedMysteryOutcome != null)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.35,
                    left: 0,
                    right: 0,
                    child: AnimatedBuilder(
                      animation: _mysteryAnimController,
                      builder: (context, child) {
                        final isReward = _isRewardOutcome(_displayedMysteryOutcome!);
                        final color = isReward
                            ? AppColors.accentGold
                            : AppColors.accentPink;
                        final bgColor = isReward
                            ? const Color(0xFF9C27B0) // Purple
                            : const Color(0xFF880E4F); // Dark pink

                        return Opacity(
                          opacity: _mysteryOpacity.value,
                          child: Transform.scale(
                            scale: _mysteryScale.value,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      bgColor,
                                      bgColor.withAlpha(220),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: color,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withAlpha(150),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getMysteryOutcomeIcon(_displayedMysteryOutcome!),
                                      color: color,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getMysteryOutcomeText(_displayedMysteryOutcome!),
                                      style: GoogleFonts.orbitron(
                                        color: color,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
      case GamePhase.letterComplete:
        return _buildLetterCompleteScreen(context, state);
      case GamePhase.gameOver:
        return _buildPlayingScreen(context, state); // Show behind overlay
    }
  }

  Widget _buildStartScreen(BuildContext context) {
    return FutureBuilder<SavedGameProgress?>(
      future: context.read<GameCubit>().getSavedProgress(),
      builder: (context, snapshot) {
        final savedProgress = snapshot.data;
        final hasSavedProgress = savedProgress != null;

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

              // Resume button (shown when saved progress exists)
              if (hasSavedProgress) ...[
                GestureDetector(
                  onTap: () => context.read<GameCubit>().resumeGame(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentCyan, AppColors.accentPurple],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentCyan.withAlpha(100),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'RESUME',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Round ${savedProgress.letterRound} · ${savedProgress.completedLetters.length}/25 letters',
                          style: GoogleFonts.exo2(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // New Game button
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
                    hasSavedProgress ? 'NEW GAME' : 'START',
                    style: GoogleFonts.orbitron(
                      color: AppColors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cancel button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withAlpha(100),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildLetterCompleteScreen(BuildContext context, GameState state) {
    final completedLetter = state.currentLetter ?? '?';

    return Column(
      children: [
        const Spacer(flex: 2),

        // Celebration icon with pulse animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
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
                child: const Icon(
                  Icons.check,
                  color: AppColors.black,
                  size: 60,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Congratulations message
        Text(
          'LETTER COMPLETE!',
          style: GoogleFonts.orbitron(
            color: AppColors.accentGold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 8),

        // Completed letter badge
        Text(
          '"$completedLetter" CLEARED',
          style: GoogleFonts.exo2(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 32),

        // Animated stats panel
        CelebrationStatsPanel(
          score: state.score,
          lettersCompleted: state.completedLetters.length,
          timeRemaining: state.timeRemaining,
          pointsEarned: state.pointsEarnedInRound,
          letterCompletionBonus: TimeConfig.letterCompletionBonus,
        ),

        const Spacer(flex: 1),

        // Continue button - appears after stats animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          // Delay the button appearance
          builder: (context, opacity, child) {
            return FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 1800)),
              builder: (context, snapshot) {
                final show = snapshot.connectionState == ConnectionState.done;
                return AnimatedOpacity(
                  opacity: show ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedScale(
                    scale: show ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    child: GestureDetector(
                      onTap: show
                          ? () => context.read<GameCubit>().continueToNextRound()
                          : null,
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
                          'CONTINUE',
                          style: GoogleFonts.orbitron(
                            color: AppColors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        const Spacer(flex: 2),
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
          letters: state.letters,
          committedWord: state.committedWord,
          celebrate: state.lastAnswerCorrect == true,
          shake: state.lastAnswerCorrect == false,
          pendingLetterId: state.pendingLetterId,
          letterDwellStartTime: state.letterDwellStartTime,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "START" label
        Text(
          'START',
          style: GoogleFonts.exo2(
            color: AppColors.accentCyan,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        // Larger, more prominent badge with cyan accent
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentCyan,
                AppColors.accentPurple,
              ],
            ),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withAlpha(180),
                blurRadius: 12,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: AppColors.accentCyan.withAlpha(100),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: AppColors.black.withAlpha(150),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Home button
          _buildIconButton(
            icon: Icons.home,
            onTap: () => _showExitConfirmation(context),
          ),

          const SizedBox(width: AppSpacing.xs),

          // Completed letters count
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

          // Center: Score display with high score (expanded to center it)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // High score target (always visible)
                  Text(
                    'BEST: $_highScore',
                    style: GoogleFonts.exo2(
                      color: state.score > _highScore
                          ? AppColors.accentGold
                          : Colors.white.withAlpha(150),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Current score
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: state.score > _highScore
                            ? [AppColors.accentGold, AppColors.accentOrange]
                            : [AppColors.accentGold.withAlpha(200), AppColors.accentOrange.withAlpha(200)],
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Timer badge
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

          const SizedBox(width: AppSpacing.xs),

          // Restart button
          _buildIconButton(
            icon: Icons.refresh,
            onTap: () => _showRestartConfirmation(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryDarkPurple.withAlpha(200),
          border: Border.all(
            color: AppColors.white.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.white.withAlpha(200),
          size: 18,
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    final state = context.read<GameCubit>().state;
    final hasCompletedLetters = state.completedLetters.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDarkPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accentGold.withAlpha(100)),
        ),
        title: Text(
          'Exit Game?',
          style: GoogleFonts.orbitron(color: AppColors.white),
        ),
        content: Text(
          hasCompletedLetters
              ? 'Your progress is saved. You can resume later.'
              : 'Your progress will be lost.',
          style: GoogleFonts.exo2(color: AppColors.white.withAlpha(200)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.exo2(color: AppColors.white.withAlpha(150)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: Text(
              'EXIT',
              style: GoogleFonts.exo2(color: AppColors.accentOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestartConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDarkPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.accentGold.withAlpha(100)),
        ),
        title: Text(
          'Restart Game?',
          style: GoogleFonts.orbitron(color: AppColors.white),
        ),
        content: Text(
          'Start a new game from the beginning.',
          style: GoogleFonts.exo2(color: AppColors.white.withAlpha(200)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.exo2(color: AppColors.white.withAlpha(150)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GameCubit>().resetGame();
              context.read<GameCubit>().startGame();
            },
            child: Text(
              'RESTART',
              style: GoogleFonts.exo2(color: AppColors.accentGold),
            ),
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
              size: 48,
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
              size: 48,
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
              size: 48,
              badgeCount: state.repeatUsageCount,
            ),
          ),

          // HINT button - shows a valid word
          GestureDetector(
            onTap: canUseHint
                ? () => context.read<GameCubit>().useHint()
                : null,
            child: ActionBubble(
              label: '?',
              isSubmit: false,
              isHint: true,
              isActive: canUseHint,
              size: 48,
              badgeCount: state.hintsRemaining,
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
              size: 48,
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
