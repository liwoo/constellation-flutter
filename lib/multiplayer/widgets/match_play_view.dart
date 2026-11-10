import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/category_jackpot.dart';
import 'package:constellation_app/game/widgets/play_area.dart';
import 'package:constellation_app/game/widgets/shooting_star.dart';
import 'package:constellation_app/multiplayer/cubit/multiplayer_cubit.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/multiplayer/widgets/match_common.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// A round in progress: this player's board, with everyone's progress
/// across the top
class MatchPlayView extends StatelessWidget {
  const MatchPlayView({super.key, required this.mp, required this.onLeave});

  final MultiplayerState mp;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final room = mp.room!;
    final roundOver = mp.stage == MatchStage.roundOver;

    return BlocBuilder<GameCubit, GameState>(
      builder: (context, game) {
        return Stack(
          children: [
            Column(
              children: [
                _Header(mp: mp, game: game, onLeave: onLeave),
                _OpponentStrip(room: room, round: mp.roundShown, me: mp.uid),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: IgnorePointer(
                    ignoring: roundOver,
                    child: switch (game.phase) {
                      GamePhase.categoryReveal => _Reveal(game: game),
                      GamePhase.playingRound => Column(
                          children: [
                            _CategoryRow(game: game),
                            const SizedBox(height: AppSpacing.sm),
                            Expanded(child: PlayArea(state: game)),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ],
            ),

            // Shooting star caught - bonus points
            Positioned(
              top: MediaQuery.of(context).size.height * 0.42,
              left: 0,
              right: 0,
              child: Center(
                child: ShootingStarCallout(
                  trigger: game.lastShootingStarBonus,
                  title: '+${game.lastShootingStarBonus ?? 0} STAR BONUS',
                  subtitle: 'Shooting star caught!',
                  duration: const Duration(milliseconds: 1800),
                ),
              ),
            ),

            // A slip autocorrected - say what it counted as
            Positioned(
              top: MediaQuery.of(context).size.height * 0.54,
              left: 0,
              right: 0,
              child: Center(child: AutocorrectCallout(word: game.lastAutocorrectedWord)),
            ),

            if (roundOver) Positioned.fill(child: _RoundOverBanner(mp: mp)),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mp, required this.game, required this.onLeave});

  final MultiplayerState mp;
  final GameState game;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final room = mp.room!;
    final seconds = game.isMatch ? game.timeRemaining : mp.secondsLeft;
    final urgent = seconds <= 15;
    final roundPoints = MatchScoring.roundPoints(room, mp.roundShown)[mp.uid] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
      child: Row(
        children: [
          MatchIconButton(icon: Icons.close, onTap: onLeave),
          const SizedBox(width: AppSpacing.sm),
          _LetterBadge(letter: game.currentLetter ?? '?'),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROUND ${mp.roundShown + 1}/${room.totalRounds}',
                  style: GoogleFonts.orbitron(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$roundPoints pts this round',
                  style: matchBodyStyle(size: 12, color: AppColors.accentGold, weight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: urgent ? AppColors.accentPink : AppColors.accentOrange,
              border: Border.all(color: AppColors.white.withAlpha(200), width: 2),
              boxShadow: [
                BoxShadow(
                  color: (urgent ? AppColors.accentPink : AppColors.accentOrange).withAlpha(120),
                  blurRadius: 12,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$seconds',
              style: GoogleFonts.orbitron(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.letter, this.size = 44});

  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [AppColors.accentYellow, AppColors.accentGold, AppColors.accentOrange]),
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: [BoxShadow(color: AppColors.accentGold.withAlpha(150), blurRadius: 14)],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.orbitron(
          color: AppColors.black,
          fontSize: size * 0.48,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Everyone's progress through the round's categories, live
class _OpponentStrip extends StatelessWidget {
  const _OpponentStrip({required this.room, required this.round, required this.me});

  final MatchRoom room;
  final int round;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final progress = room.progress(round);
    return SizedBox(
      height: 62,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              for (final player in room.roster)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _OpponentChip(
                    player: player,
                    color: seatColor(room, player.uid),
                    answered: progress[player.uid] ?? 0,
                    isYou: player.uid == me,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpponentChip extends StatelessWidget {
  const _OpponentChip({
    required this.player,
    required this.color,
    required this.answered,
    required this.isYou,
  });

  final MatchPlayer player;
  final Color color;
  final int answered;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatar(player: player, color: color, size: 28),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < GameState.categoriesPerLetter; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < answered ? color : AppColors.white.withAlpha(50),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 54,
          child: Text(
            isYou ? 'YOU' : player.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: matchBodyStyle(size: 10, color: isYou ? AppColors.accentGold : null, weight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Text(
          'CATEGORY ${game.categoryIndex + 1} OF ${GameState.categoriesPerLetter}',
          style: matchBodyStyle(size: 13, weight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.lg),
        CategoryJackpot(
          // A fresh spin for each category, including one put off for later
          key: ValueKey('${game.matchRound?.number}-${game.categoryIndex}-${game.category}'),
          targetCategory: game.category,
          duration: const Duration(milliseconds: 1600),
          onComplete: context.read<GameCubit>().onCategoryRevealed,
        ),
        const Spacer(),
      ],
    );
  }
}

/// The category, a "later" button to put it to the back of the queue, and
/// how many are done
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    // No skipping in multiplayer - everyone races the same categories in turn
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: CategoryBanner(category: game.category)),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryPurple.withAlpha(200),
              border: Border.all(color: AppColors.accentGold.withAlpha(150), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '${game.categoryIndex + 1}/${GameState.categoriesPerLetter}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// A beat between the last word and the scoreboard: who ended the round
class _RoundOverBanner extends StatelessWidget {
  const _RoundOverBanner({required this.mp});

  final MultiplayerState mp;

  @override
  Widget build(BuildContext context) {
    final room = mp.room!;
    final end = room.ends[mp.roundShown];
    final finisher = end?.by == null ? null : room.players[end!.by];
    final subtitle = switch (finisher) {
      null => 'Time\'s up!',
      _ when finisher.uid == mp.uid => 'You finished first!',
      _ => '${finisher.name} finished first!',
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Container(
        color: AppColors.black.withAlpha((150 * t.clamp(0.0, 1.0)).round()),
        alignment: Alignment.center,
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MatchHeading('ROUND OVER', size: 30, color: AppColors.accentGold),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: matchBodyStyle(size: 18, color: AppColors.white, weight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Countdown before the first round
class MatchIntroView extends StatelessWidget {
  const MatchIntroView({super.key, required this.mp});

  final MultiplayerState mp;

  @override
  Widget build(BuildContext context) {
    final room = mp.room!;
    final letter = room.setup?.rounds.firstOrNull?.letter ?? '?';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MatchHeading('ROUND 1 OF ${room.totalRounds}', size: 18),
          const SizedBox(height: AppSpacing.lg),
          _LetterBadge(letter: letter, size: 110),
          const SizedBox(height: AppSpacing.lg),
          Text('Every answer starts with $letter', style: matchBodyStyle(size: 16)),
          const SizedBox(height: AppSpacing.xl),
          TweenAnimationBuilder<double>(
            key: ValueKey(mp.secondsToStart),
            tween: Tween(begin: 1.6, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: MatchHeading('${mp.secondsToStart}', size: 56, color: AppColors.accentCyan),
          ),
        ],
      ),
    );
  }
}
