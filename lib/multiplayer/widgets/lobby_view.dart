import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:constellation_app/multiplayer/cubit/multiplayer_cubit.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/multiplayer/widgets/match_common.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// Waiting for friends: the room code to share, who's here, and (for the
/// host) the start button
class LobbyView extends StatelessWidget {
  const LobbyView({super.key, required this.state, required this.onLeave});

  final MultiplayerState state;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final room = state.room!;
    final roster = room.roster;
    final host = room.players[room.hostUid];
    final online = room.onlinePlayers.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              MatchIconButton(icon: Icons.close, onTap: onLeave),
              const Expanded(child: MatchHeading('LOBBY', size: 20)),
              const SizedBox(width: 36),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                _RoomCode(code: room.code),
                const SizedBox(height: AppSpacing.md),
                MatchPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLAYERS ${roster.length}/${MultiplayerConfig.maxPlayers}',
                        style: GoogleFonts.exo2(
                          color: AppColors.white.withAlpha(160),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final player in roster)
                        _PlayerRow(
                          player: player,
                          color: seatColor(room, player.uid),
                          isHost: player.uid == room.hostUid,
                          isYou: player.uid == state.uid,
                        ),
                      for (var i = roster.length; i < MultiplayerConfig.maxPlayers; i++) const _EmptySeat(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _HowItWorks(),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: state.isHost
              ? Column(
                  children: [
                    GameButton(
                      text: room.canStart ? 'START GAME' : 'WAITING FOR PLAYERS',
                      width: double.infinity,
                      onPressed: room.canStart ? context.read<MultiplayerCubit>().startMatch : null,
                    ),
                    if (!room.canStart) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Invite at least one friend to start',
                        style: matchBodyStyle(size: 12),
                      ),
                    ],
                  ],
                )
              : Text(
                  online < MultiplayerConfig.minPlayers
                      ? 'Waiting for more players…'
                      : 'Waiting for ${host?.name ?? 'the host'} to start…',
                  textAlign: TextAlign.center,
                  style: matchBodyStyle(size: 15, color: AppColors.accentGold, weight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}

class _RoomCode extends StatelessWidget {
  const _RoomCode({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return MatchPanel(
      child: Column(
        children: [
          Text('ROOM CODE', style: matchBodyStyle(size: 11, weight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            code,
            style: GoogleFonts.orbitron(
              color: AppColors.accentGold,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () async {
              AudioService.instance.play(GameSound.buttonTap);
              HapticService.instance.selection();
              await Clipboard.setData(ClipboardData(text: inviteMessage(code)));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invite copied - send it to your friends',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.exo2(fontWeight: FontWeight.bold, color: AppColors.black),
                  ),
                  backgroundColor: AppColors.accentGold,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentGold.withAlpha(160)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ios_share, color: AppColors.accentGold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'COPY INVITE',
                    style: GoogleFonts.exo2(
                      color: AppColors.accentGold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.color,
    required this.isHost,
    required this.isYou,
  });

  final MatchPlayer player;
  final Color color;
  final bool isHost;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          PlayerAvatar(
            player: player,
            color: color,
            badge: isHost ? const Icon(Icons.workspace_premium, color: AppColors.accentGold, size: 18) : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isYou ? '${player.name} (you)' : player.name,
              overflow: TextOverflow.ellipsis,
              style: matchBodyStyle(size: 16, color: AppColors.white, weight: FontWeight.bold),
            ),
          ),
          if (!player.online) Text('away', style: matchBodyStyle(size: 12, color: AppColors.greyMedium)),
          if (isHost && player.online) Text('host', style: matchBodyStyle(size: 12, color: AppColors.accentGold)),
        ],
      ),
    );
  }
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withAlpha(50), width: 1.5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Open seat', style: matchBodyStyle(size: 14, color: AppColors.white.withAlpha(70))),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final rules = [
      (Icons.school_rounded, 'A quick warm-up first: everyone spells the same word, then the host starts'),
      (Icons.grid_view_rounded, '${MultiplayerConfig.rounds} rounds - everyone gets the same letter, categories and stars'),
      (Icons.flag_rounded, 'First to answer all 5 categories ends the round for everyone'),
      (Icons.auto_awesome, 'A word nobody else found scores ${MultiplayerConfig.uniqueMultiplier}x'),
      (Icons.star_rounded, 'Catch a shooting star in your word for ${ShootingStarConfig.scoreMultiplier}x points'),
      (
        Icons.spellcheck,
        'A slip in a ${AutocorrectConfig.minLength}+ letter word is autocorrected for '
            '${(AutocorrectConfig.pointsShare * 100).round()}% points',
      ),
      (Icons.leaderboard_rounded, 'Scores show for ${MultiplayerConfig.scoreboardSeconds}s before each round'),
    ];
    return MatchPanel(
      child: Column(
        children: [
          for (final (icon, text) in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.accentCyan, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(text, style: matchBodyStyle(size: 13))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
