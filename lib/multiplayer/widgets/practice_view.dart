import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/play_area.dart';
import 'package:constellation_app/multiplayer/cubit/multiplayer_cubit.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/multiplayer/widgets/match_common.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// The warm-up before scoring: everyone spells the same word to show they
/// know how to play. Once you've done it you wait; the host starts the match
/// when the whole table is ready.
class PracticeView extends StatelessWidget {
  const PracticeView({super.key, required this.mp, required this.onLeave});

  final MultiplayerState mp;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final room = mp.room!;
    final word = room.setup?.practiceWord ?? '';
    final iAmReady = room.isReady(mp.uid ?? '');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              MatchIconButton(icon: Icons.close, onTap: onLeave),
              const Expanded(child: MatchHeading('WARM-UP', size: 20)),
              const SizedBox(width: 36),
            ],
          ),
        ),
        _ReadyStrip(room: room, me: mp.uid),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: iAmReady
              ? _WaitingView(mp: mp)
              : _SpellView(word: word),
        ),
      ],
    );
  }
}

/// The board where you spell the shared word
class _SpellView extends StatelessWidget {
  const _SpellView({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, game) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  Text(
                    'Connect the stars to spell',
                    style: matchBodyStyle(size: 13),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    word.split('').join(' '),
                    style: GoogleFonts.orbitron(
                      color: AppColors.accentGold,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: PlayArea(state: game)),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }
}

/// You're ready - waiting for the rest of the table and the host to start
class _WaitingView extends StatelessWidget {
  const _WaitingView({required this.mp});

  final MultiplayerState mp;

  @override
  Widget build(BuildContext context) {
    final room = mp.room!;
    final waitingOn = room.onlinePlayers.where((p) => !room.isReady(p.uid)).toList();
    final allReady = waitingOn.isEmpty;
    final host = room.players[room.hostUid];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Icon(Icons.check_circle, color: Color(0xFF69F0AE), size: 72),
          const SizedBox(height: AppSpacing.md),
          const MatchHeading("YOU'RE READY", size: 24, color: AppColors.accentGold),
          const SizedBox(height: AppSpacing.sm),
          Text(
            allReady
                ? 'Everyone has warmed up!'
                : waitingOn.length == 1
                    ? 'Waiting for ${waitingOn.first.name}…'
                    : 'Waiting for ${waitingOn.length} more players…',
            textAlign: TextAlign.center,
            style: matchBodyStyle(size: 15, color: AppColors.white, weight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (mp.isHost)
            GameButton(
              text: allReady ? 'START GAME' : 'WAITING FOR PLAYERS',
              width: double.infinity,
              onPressed: room.canStartScoring
                  ? context.read<MultiplayerCubit>().startScoring
                  : null,
            )
          else
            Text(
              'Waiting for ${host?.name ?? 'the host'} to start the game…',
              textAlign: TextAlign.center,
              style: matchBodyStyle(size: 15, color: AppColors.accentGold, weight: FontWeight.bold),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Who at the table has warmed up, so far
class _ReadyStrip extends StatelessWidget {
  const _ReadyStrip({required this.room, required this.me});

  final MatchRoom room;
  final String? me;

  @override
  Widget build(BuildContext context) {
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
                  child: _ReadyChip(
                    player: player,
                    color: seatColor(room, player.uid),
                    ready: room.isReady(player.uid),
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

class _ReadyChip extends StatelessWidget {
  const _ReadyChip({
    required this.player,
    required this.color,
    required this.ready,
    required this.isYou,
  });

  final MatchPlayer player;
  final Color color;
  final bool ready;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatar(
          player: player,
          color: color,
          size: 28,
          badge: ready
              ? const Icon(Icons.check_circle, color: Color(0xFF69F0AE), size: 16)
              : null,
        ),
        const SizedBox(height: 3),
        Text(
          ready ? 'ready' : 'warming up',
          style: matchBodyStyle(size: 10, color: ready ? const Color(0xFF69F0AE) : null, weight: FontWeight.bold),
        ),
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
