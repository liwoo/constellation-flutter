import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/main_menu/cubit/cubit.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// {@template main_menu_body}
/// Body of the MainMenuPage.
///
/// Main menu screen with game title, decorative stars, and navigation buttons
/// {@endtemplate}
class MainMenuBody extends StatelessWidget {
  /// {@macro main_menu_body}
  const MainMenuBody({super.key});

  static const double _buttonWidth = 220.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMenuCubit, MainMenuState>(
      builder: (context, state) {
        return GradientBackground(
          child: Stack(
            children: [
              // Star decorations
              const Positioned.fill(
                child: StarDecoration(starCount: 100, starSize: 3.0),
              ),

              // Decorative constellation lines
              const Positioned(
                top: 80,
                right: 30,
                child: _ConstellationDecoration(size: 80),
              ),
              const Positioned(
                bottom: 120,
                left: 20,
                child: _ConstellationDecoration(size: 60),
              ),
              const Positioned(
                bottom: 200,
                right: 40,
                child: _ConstellationDecoration(size: 50),
              ),

              // Settings icon in bottom right corner
              Positioned(
                bottom: 16,
                right: 16,
                child: SafeArea(
                  child: _IconButton(
                    icon: Icons.settings,
                    onPressed: () => context.go('/settings'),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Top bar with sound toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Info button
                          _IconButton(
                            icon: Icons.info_outline,
                            onPressed: () => _showAboutDialog(context),
                          ),
                          // Sound toggle
                          _SoundToggleButton(
                            isEnabled: state.soundEnabled,
                            onPressed: () {
                              context.read<MainMenuCubit>().toggleSound();
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Player Avatar
                    _PlayerAvatar(playerName: state.playerName),

                    const SizedBox(height: AppSpacing.lg),

                    // Game Title
                    Text(
                      'CONSTELLATION',
                      style: GoogleFonts.orbitron(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        fontSize: 28,
                        shadows: [
                          Shadow(
                            color: AppColors.black.withAlpha(128),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Subtitle
                    Text(
                      'WORD GAME',
                      style: GoogleFonts.exo2(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4.0,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Stats display
                    _StatsDisplay(
                      highScore: state.highScore,
                      gamesPlayed: state.gamesPlayed,
                    ),

                    const Spacer(flex: 1),

                    // Star balance display
                    _StarBalanceDisplay(stars: state.stars),

                    const SizedBox(height: AppSpacing.lg),

                    // Menu buttons - all same width
                    Column(
                      children: [
                        // Alpha Quest button (primary)
                        GameButton(
                          text: 'ALPHA QUEST',
                          onPressed: () => context.go('/game'),
                          isPrimary: true,
                          width: _buttonWidth,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Practice mode
                        GameButton(
                          text: 'PRACTICE',
                          onPressed: () => context.go('/practice'),
                          isPrimary: false,
                          width: _buttonWidth,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // How to Play
                        GameButton(
                          text: 'HOW TO PLAY',
                          onPressed: () => _showHowToPlayDialog(context),
                          isPrimary: false,
                          width: _buttonWidth,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // High Scores
                        GameButton(
                          text: 'HIGH SCORES',
                          onPressed: () => _showHighScoresDialog(context, state),
                          isPrimary: false,
                          width: _buttonWidth,
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // Footer with settings icon
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'v1.0.0',
                            style: GoogleFonts.exo2(
                              color: AppColors.white.withAlpha(102),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHighScoresDialog(BuildContext context, MainMenuState state) {
    showDialog(
      context: context,
      builder: (context) => _GameDialog(
        title: 'HIGH SCORES',
        icon: Icons.emoji_events,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stats summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniStat(label: 'GAMES', value: state.gamesPlayed.toString()),
                _MiniStat(label: 'WINS', value: state.totalWins.toString()),
                _MiniStat(label: 'BEST', value: state.highScore.toString()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Top scores list
            if (state.topScores.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No games played yet!\nStart playing to set records.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo2(
                    color: AppColors.white.withAlpha(150),
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...state.topScores.take(5).map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _HighScoreRow(
                  rank: entry.rank,
                  score: entry.score,
                  lettersCompleted: entry.lettersCompleted,
                ),
              )),
            const SizedBox(height: AppSpacing.md),
            GameButton(
              text: 'CLOSE',
              onPressed: () => Navigator.of(context).pop(),
              isPrimary: true,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _GameDialog(
        title: 'HOW TO PLAY',
        icon: Icons.help_outline,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpItem(
              number: '1',
              text: 'Connect letters to form words matching the category',
            ),
            const SizedBox(height: AppSpacing.md),
            _HelpItem(
              number: '2',
              text: 'Drag between letters to create connections',
            ),
            const SizedBox(height: AppSpacing.md),
            _HelpItem(
              number: '3',
              text: 'Longer words and rare letters score more points',
            ),
            const SizedBox(height: AppSpacing.md),
            _HelpItem(
              number: '4',
              text: 'Complete as many words as you can before time runs out',
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: GameButton(
                text: 'GOT IT',
                onPressed: () => Navigator.of(context).pop(),
                isPrimary: true,
                width: 160,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _GameDialog(
        title: 'ABOUT',
        icon: Icons.info_outline,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CONSTELLATION',
              style: GoogleFonts.orbitron(
                color: AppColors.accentGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A word puzzle game set among the stars',
              style: GoogleFonts.exo2(
                color: AppColors.white.withAlpha(200),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Connect letters to form words and\nunlock the constellations!',
              style: GoogleFonts.exo2(
                color: AppColors.white.withAlpha(150),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GameButton(
              text: 'CLOSE',
              onPressed: () => Navigator.of(context).pop(),
              isPrimary: true,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable game dialog
class _GameDialog extends StatelessWidget {
  const _GameDialog({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDarkPurple,
              AppColors.primaryNavy,
            ],
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: Border.all(
            color: AppColors.accentGold.withAlpha(128),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withAlpha(128),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.accentGold, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

/// Help item with numbered step
class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentGold,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.orbitron(
                color: AppColors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: GoogleFonts.exo2(
                color: AppColors.white.withAlpha(220),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Icon button for top bar
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPurple.withAlpha(179),
              AppColors.primaryDarkPurple.withAlpha(179),
            ],
          ),
          border: Border.all(
            color: AppColors.white.withAlpha(77),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.white.withAlpha(200),
          size: 24,
        ),
      ),
    );
  }
}

/// Sound toggle button with glow effect
class _SoundToggleButton extends StatelessWidget {
  const _SoundToggleButton({
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryPurple.withAlpha(179),
              AppColors.primaryDarkPurple.withAlpha(179),
            ],
          ),
          border: Border.all(
            color: isEnabled
                ? AppColors.accentGold.withAlpha(179)
                : AppColors.greyMedium.withAlpha(128),
            width: 2,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.accentGold.withAlpha(77),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          isEnabled ? Icons.volume_up : Icons.volume_off,
          color: isEnabled ? AppColors.accentGold : AppColors.greyMedium,
          size: 24,
        ),
      ),
    );
  }
}

/// Player avatar with decorative ring
class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.playerName});

  final String playerName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentPink.withAlpha(230),
                AppColors.primaryPurple.withAlpha(230),
              ],
            ),
            border: Border.all(
              color: AppColors.accentPink,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPink.withAlpha(77),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          playerName,
          style: GoogleFonts.exo2(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Stats display showing high score and games played
class _StatsDisplay extends StatelessWidget {
  const _StatsDisplay({
    required this.highScore,
    required this.gamesPlayed,
  });

  final int highScore;
  final int gamesPlayed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(
          icon: Icons.emoji_events,
          label: 'BEST',
          value: highScore.toString(),
        ),
        Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          color: AppColors.white.withAlpha(51),
        ),
        _StatItem(
          icon: Icons.games,
          label: 'GAMES',
          value: gamesPlayed.toString(),
        ),
      ],
    );
  }
}

/// Individual stat item
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.accentGold,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: GoogleFonts.exo2(
                color: AppColors.white.withAlpha(179),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: AppColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Mini stat for high scores dialog header
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.exo2(
            color: AppColors.white.withAlpha(150),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: AppColors.accentGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// High score row for leaderboard
class _HighScoreRow extends StatelessWidget {
  const _HighScoreRow({
    required this.rank,
    required this.score,
    this.lettersCompleted = 0,
  });

  final int rank;
  final int score;
  final int lettersCompleted;

  @override
  Widget build(BuildContext context) {
    final Color rankColor = rank == 1
        ? AppColors.accentGold
        : rank == 2
            ? AppColors.greyLight
            : rank == 3
                ? AppColors.accentOrange
                : AppColors.primaryPurple;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: rank <= 3
            ? Border.all(color: rankColor.withAlpha(100), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      Icons.emoji_events,
                      color: rank == 1 ? AppColors.black : AppColors.white,
                      size: 16,
                    )
                  : Text(
                      rank.toString(),
                      style: GoogleFonts.orbitron(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$score pts',
                  style: GoogleFonts.orbitron(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$lettersCompleted/25 letters',
                  style: GoogleFonts.exo2(
                    color: AppColors.white.withAlpha(150),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (lettersCompleted >= 25)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'WIN',
                style: GoogleFonts.orbitron(
                  color: AppColors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Decorative constellation pattern
class _ConstellationDecoration extends StatelessWidget {
  const _ConstellationDecoration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ConstellationPainter(),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGold.withAlpha(153)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.fill;

    // Create random-looking constellation pattern
    final random = math.Random(42);
    final points = <Offset>[];

    for (int i = 0; i < 5; i++) {
      points.add(Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      ));
    }

    // Draw lines
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    // Draw dots at each point
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Star balance display showing actual star count
class _StarBalanceDisplay extends StatelessWidget {
  const _StarBalanceDisplay({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withAlpha(30),
            AppColors.accentOrange.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentGold.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star icon with glow
          Container(
            width: 32,
            height: 32,
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withAlpha(100),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Star count
          Text(
            '$stars',
            style: GoogleFonts.orbitron(
              color: AppColors.accentGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'STARS',
            style: GoogleFonts.exo2(
              color: AppColors.accentGold.withAlpha(180),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
