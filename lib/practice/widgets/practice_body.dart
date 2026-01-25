import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/practice/cubit/cubit.dart';
import 'package:constellation_app/practice/widgets/target_word_display.dart';
import 'package:constellation_app/game/widgets/letter_constellation.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// {@template practice_body}
/// Body of the PracticePage - practice mode to learn mechanics.
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
              // Star decorations
              const Positioned.fill(
                child: StarDecoration(starCount: 100, starSize: 2),
              ),

              // Main content based on phase
              SafeArea(
                child: _buildPhaseContent(context, state),
              ),

              // Tutorial modal overlay
              if (state.showTutorial != null)
                _buildTutorialOverlay(context, state.showTutorial!),

              // Completion overlay
              if (state.phase == PracticePhase.completed)
                _buildCompletionOverlay(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhaseContent(BuildContext context, PracticeState state) {
    switch (state.phase) {
      case PracticePhase.notStarted:
        return _buildStartScreen(context);
      case PracticePhase.playing:
        return _buildPlayingScreen(context, state);
      case PracticePhase.completed:
        return _buildPlayingScreen(context, state);
    }
  }

  Widget _buildStartScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            color: AppColors.accentGold,
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            'PRACTICE MODE',
            style: GoogleFonts.orbitron(
              color: AppColors.accentGold,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Learn to connect letters by spelling\nthe target words shown above',
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(
                color: Colors.white.withAlpha(200),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '10 words \u2022 Progressive difficulty',
            style: GoogleFonts.exo2(
              color: AppColors.accentGold.withAlpha(180),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: () => context.read<PracticeCubit>().startSession(),
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
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/'),
            child: Text(
              'Back to Menu',
              style: GoogleFonts.exo2(
                color: Colors.white.withAlpha(150),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingScreen(BuildContext context, PracticeState state) {
    return Column(
      children: [
        // Top bar with progress and back button
        _buildTopBar(context, state),

        const SizedBox(height: AppSpacing.md),

        // Progress indicator
        _buildProgressIndicator(state),

        const SizedBox(height: AppSpacing.md),

        // Word counter
        Text(
          'Word ${state.currentWordIndex + 1} of ${PracticeState.wordsPerSession}',
          style: GoogleFonts.exo2(
            color: Colors.white.withAlpha(150),
            fontSize: 12,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Target word display (greyed out letters to spell)
        if (state.currentWord != null)
          TargetWordDisplay(
            targetWord: state.currentWord!.word,
            builtWord: state.builtWord,
            showSuccess: state.showSuccess,
          ),

        const SizedBox(height: AppSpacing.md),

        // Letter constellation
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: LetterConstellation(
              letters: state.letters,
              selectedLetterIds: state.selectedLetterIds,
              currentDragPosition: state.currentDragPosition,
              isDragging: state.isDragging,
              onDragStart: (pos) {
                context.read<PracticeCubit>().startDrag(pos);
              },
              onDragUpdate: (pos) {
                context.read<PracticeCubit>().updateDrag(pos);
              },
              onDragEnd: () {
                context.read<PracticeCubit>().endDrag();
              },
            ),
          ),
        ),

        // Action buttons
        _buildActionButtons(context, state),

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryPurple.withAlpha(150),
                border: Border.all(
                  color: Colors.white.withAlpha(80),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          // Title
          Text(
            'PRACTICE',
            style: GoogleFonts.orbitron(
              color: AppColors.accentGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          // Skip button
          GestureDetector(
            onTap: () => context.read<PracticeCubit>().skipWord(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withAlpha(80),
                  width: 1,
                ),
              ),
              child: Text(
                'SKIP',
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(PracticeState state) {
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

  Widget _buildActionButtons(BuildContext context, PracticeState state) {
    final hasSelection = state.selectedLetterIds.isNotEmpty;
    final hasContent = state.hasWordContent;
    final canAddSpace = hasSelection;
    final canRepeat = hasSelection;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // DEL button
          GestureDetector(
            onTap: hasContent
                ? () => context.read<PracticeCubit>().clearSelection()
                : null,
            child: ActionBubble(
              label: 'DEL',
              isSubmit: false,
              isActive: hasContent,
              size: 55,
            ),
          ),

          // SPACE button
          GestureDetector(
            onTap: canAddSpace
                ? () => context.read<PracticeCubit>().insertSpace()
                : null,
            child: ActionBubble(
              label: '\u2423',
              isSubmit: false,
              isBonus: true,
              isActive: canAddSpace,
              size: 55,
            ),
          ),

          // x2 button
          GestureDetector(
            onTap: canRepeat
                ? () => context.read<PracticeCubit>().repeatLastLetter()
                : null,
            child: ActionBubble(
              label: 'x2',
              isSubmit: false,
              isBonus: true,
              isActive: canRepeat,
              size: 55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialOverlay(BuildContext context, TutorialType tutorial) {
    // Determine tutorial content based on type
    final (icon, title, explanation, tipIcon, tipText) = switch (tutorial) {
      TutorialType.dragIndicators => (
        Icons.touch_app,
        'HOW TO CONNECT',
        'Drag your finger across the letters\nto spell words',
        null, // Uses custom tips section
        null,
      ),
      TutorialType.doubleLetters => (
        Icons.repeat,
        'DOUBLE LETTERS',
        'This word has double letters\n(like SS in MISSISSIPPI)',
        'x2',
        'Tap x2 to repeat\nthe last letter',
      ),
      TutorialType.spacedWords => (
        Icons.space_bar,
        'MULTI-WORD',
        'This is a multi-word phrase\n(like ICE CREAM)',
        '\u2423',
        'Tap space to add\na space between words',
      ),
      TutorialType.navigation => (
        Icons.route,
        'TRICKY PATH',
        'This word has letters far apart.\nOther letters may be in your way!',
        null, // No button tip for navigation
        null,
      ),
    };

    return Container(
      color: AppColors.black.withAlpha(220),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPurple.withAlpha(250),
                AppColors.primaryDarkPurple.withAlpha(250),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.accentCyan,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withAlpha(100),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentCyan, AppColors.accentPurple],
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: AppColors.accentCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              // Explanation
              Text(
                explanation,
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(220),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // How to handle it - different content based on tutorial type
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: switch (tutorial) {
                  TutorialType.dragIndicators => _buildDragIndicatorsTips(),
                  TutorialType.navigation => _buildNavigationTips(),
                  _ => _buildButtonTip(tipIcon!, tipText!),
                },
              ),

              const SizedBox(height: 24),

              // Got it button
              GestureDetector(
                onTap: () => context.read<PracticeCubit>().dismissTutorial(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentCyan, AppColors.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withAlpha(100),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'GOT IT!',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
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

  /// Build the button tip for double letters and spaced words
  Widget _buildButtonTip(String buttonLabel, String tipText) {
    return Column(
      children: [
        Text(
          'HOW TO SPELL IT:',
          style: GoogleFonts.exo2(
            color: AppColors.accentGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentGold, AppColors.accentOrange],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.orbitron(
                  color: AppColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                tipText,
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(200),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build navigation tips for tricky paths
  Widget _buildNavigationTips() {
    return Column(
      children: [
        Text(
          'HOW TO NAVIGATE:',
          style: GoogleFonts.exo2(
            color: AppColors.accentGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        // Tip 1: Slow down
        _buildNavigationTipRow(
          Icons.slow_motion_video,
          'Slow down near your target letter',
        ),
        const SizedBox(height: 12),
        // Tip 2: Curve around
        _buildNavigationTipRow(
          Icons.gesture,
          'Curve around letters in the way',
        ),
        const SizedBox(height: 12),
        // Tip 3: Use DEL
        _buildNavigationTipRow(
          Icons.backspace_outlined,
          'Tap DEL if you select the wrong letter',
        ),
      ],
    );
  }

  /// Build drag indicators tips for connection tutorial
  Widget _buildDragIndicatorsTips() {
    return Column(
      children: [
        Text(
          'VISUAL INDICATORS:',
          style: GoogleFonts.exo2(
            color: AppColors.accentGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        // Tip 1: Approaching glow
        _buildNavigationTipRow(
          Icons.lightbulb_outline,
          'Letters glow and grow when you approach',
        ),
        const SizedBox(height: 12),
        // Tip 2: Dwell progress
        _buildNavigationTipRow(
          Icons.timelapse,
          'A ring fills up - hold still to connect',
        ),
        const SizedBox(height: 12),
        // Tip 3: Connection flash
        _buildNavigationTipRow(
          Icons.flash_on,
          'Letters flash when successfully connected',
        ),
        const SizedBox(height: 12),
        // Tip 4: Line follows
        _buildNavigationTipRow(
          Icons.timeline,
          'A line traces your path between letters',
        ),
      ],
    );
  }

  Widget _buildNavigationTipRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentCyan.withAlpha(50),
          ),
          child: Icon(
            icon,
            color: AppColors.accentCyan,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.exo2(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionOverlay(BuildContext context, PracticeState state) {
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
              color: AppColors.accentGold,
              width: 3,
            ),
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
              const Icon(
                Icons.celebration,
                color: AppColors.accentGold,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'PRACTICE COMPLETE!',
                style: GoogleFonts.orbitron(
                  color: AppColors.accentGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You spelled all ${state.completedCount} words!',
                style: GoogleFonts.exo2(
                  color: Colors.white.withAlpha(200),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You're ready for Alpha Quest!",
                style: GoogleFonts.exo2(
                  color: AppColors.accentGold.withAlpha(200),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // Play Alpha Quest button
              GestureDetector(
                onTap: () => context.go('/game'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
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
              const SizedBox(height: 16),
              // Practice again button
              GestureDetector(
                onTap: () => context.read<PracticeCubit>().startSession(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
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
                    'PRACTICE AGAIN',
                    style: GoogleFonts.orbitron(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Menu button
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  'Back to Menu',
                  style: GoogleFonts.exo2(
                    color: Colors.white.withAlpha(150),
                    fontSize: 14,
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
