import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/multiplayer/cubit/multiplayer_cubit.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/multiplayer/widgets/match_common.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// Standings and every player's words for the round just played. Between
/// rounds it counts down to the next; after the last it's the final result.
class ScoreboardView extends StatelessWidget {
  const ScoreboardView({super.key, required this.mp, required this.onLeave});

  final MultiplayerState mp;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final room = mp.room!;
    final isFinal = mp.stage == MatchStage.finished;
    final round = mp.roundShown;
    final standings = MatchScoring.standings(room);
    final roundPoints = MatchScoring.roundPoints(room, round);
    final scored = MatchScoring.scoreRound(room, round);
    final categories = room.setup?.rounds.elementAtOrNull(round)?.categories ?? const <String>[];
    final end = room.ends[round];
    final finisher = end?.by == null ? null : room.players[end!.by];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              MatchIconButton(icon: Icons.close, onTap: onLeave),
              Expanded(
                child: MatchHeading(
                  isFinal ? 'FINAL STANDINGS' : 'ROUND ${round + 1} RESULTS',
                  size: 18,
                  color: isFinal ? AppColors.accentGold : AppColors.white,
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        if (!isFinal)
          Text(
            finisher == null ? 'Time ran out' : '${finisher.uid == mp.uid ? 'You' : finisher.name} finished first',
            style: matchBodyStyle(size: 13),
          ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              MatchPanel(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    for (final (rank, entry) in standings.indexed)
                      _StandingRow(
                        rank: rank + 1,
                        player: entry.key,
                        color: seatColor(room, entry.key.uid),
                        total: entry.value,
                        roundPoints: isFinal ? null : roundPoints[entry.key.uid] ?? 0,
                        isYou: entry.key.uid == mp.uid,
                        isWinner: isFinal && rank == 0,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (categories.isNotEmpty) ...[
                Text(
                  isFinal ? 'LAST ROUND\'S WORDS' : 'WORDS',
                  style: GoogleFonts.exo2(
                    color: AppColors.white.withAlpha(160),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final (index, category) in categories.indexed)
                  _CategoryResults(
                    category: category,
                    room: room,
                    answers: {
                      for (final p in room.roster)
                        if (scored[p.uid]?[index] case final answer?) p: answer,
                    },
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: isFinal
              ? Column(
                  children: [
                    if (mp.isHost)
                      GameButton(
                        text: 'PLAY AGAIN',
                        width: double.infinity,
                        onPressed: context.read<MultiplayerCubit>().playAgain,
                      )
                    else
                      Text(
                        'The host can start a rematch',
                        style: matchBodyStyle(size: 13),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    GameButton(
                      text: 'LEAVE',
                      isPrimary: false,
                      width: double.infinity,
                      onPressed: onLeave,
                    ),
                  ],
                )
              : _NextRoundCountdown(
                  round: room.round + 1,
                  totalRounds: room.totalRounds,
                  seconds: mp.secondsToStart,
                ),
        ),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.rank,
    required this.player,
    required this.color,
    required this.total,
    required this.roundPoints,
    required this.isYou,
    required this.isWinner,
  });

  final int rank;
  final MatchPlayer player;
  final Color color;
  final int total;
  final int? roundPoints;
  final bool isYou;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: GoogleFonts.orbitron(
                color: rank == 1 ? AppColors.accentGold : AppColors.white.withAlpha(180),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PlayerAvatar(
            player: player,
            color: color,
            size: isWinner ? 44 : 34,
            badge: isWinner ? const Icon(Icons.emoji_events, color: AppColors.accentGold, size: 22) : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isYou ? '${player.name} (you)' : player.name,
              overflow: TextOverflow.ellipsis,
              style: matchBodyStyle(
                size: 16,
                color: isYou ? AppColors.accentGold : AppColors.white,
                weight: FontWeight.bold,
              ),
            ),
          ),
          if (roundPoints != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                '+$roundPoints',
                style: matchBodyStyle(size: 14, color: AppColors.accentCyan, weight: FontWeight.bold),
              ),
            ),
          Text(
            '$total',
            style: GoogleFonts.orbitron(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// One category: who found what, unique finds called out
class _CategoryResults extends StatelessWidget {
  const _CategoryResults({required this.category, required this.room, required this.answers});

  final String category;
  final MatchRoom room;
  final Map<MatchPlayer, ScoredAnswer> answers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MatchPanel(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: GoogleFonts.orbitron(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (answers.isEmpty)
              Text('Nobody got this one', style: matchBodyStyle(size: 12, color: AppColors.white.withAlpha(110)))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final MapEntry(key: player, value: answer) in answers.entries)
                    _AnswerChip(player: player, color: seatColor(room, player.uid), answer: answer),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({required this.player, required this.color, required this.answer});

  final MatchPlayer player;
  final Color color;
  final ScoredAnswer answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answer.isUnique ? AppColors.accentGold : color.withAlpha(120),
          width: answer.isUnique ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            answer.word.toUpperCase(),
            style: matchBodyStyle(size: 12, color: AppColors.white, weight: FontWeight.bold),
          ),
          const SizedBox(width: 5),
          Text(
            '+${answer.points}',
            style: matchBodyStyle(
              size: 11,
              color: answer.isUnique ? AppColors.accentGold : AppColors.white.withAlpha(150),
              weight: FontWeight.bold,
            ),
          ),
          // Why the same word can score differently
          if (answer.caughtStar) ...[
            const SizedBox(width: 3),
            const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 13),
          ],
          if (answer.isAutocorrected) ...[
            const SizedBox(width: 3),
            Icon(Icons.spellcheck, color: AppColors.white.withAlpha(150), size: 13),
          ],
          if (answer.isUnique) ...[
            const SizedBox(width: 3),
            const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 12),
          ],
        ],
      ),
    );
  }
}

class _NextRoundCountdown extends StatelessWidget {
  const _NextRoundCountdown({required this.round, required this.totalRounds, required this.seconds});

  final int round;
  final int totalRounds;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final progress = (seconds / MultiplayerConfig.scoreboardSeconds).clamp(0.0, 1.0);
    return Column(
      children: [
        Text(
          round == totalRounds ? 'FINAL ROUND IN ${seconds}s' : 'ROUND $round OF $totalRounds IN ${seconds}s',
          style: GoogleFonts.orbitron(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 250),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.white.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation(AppColors.accentGold),
            ),
          ),
        ),
      ],
    );
  }
}
