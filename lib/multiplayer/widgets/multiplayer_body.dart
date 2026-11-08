import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/multiplayer/cubit/multiplayer_cubit.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/multiplayer/widgets/lobby_view.dart';
import 'package:constellation_app/multiplayer/widgets/match_common.dart';
import 'package:constellation_app/multiplayer/widgets/match_entry_view.dart';
import 'package:constellation_app/multiplayer/widgets/match_play_view.dart';
import 'package:constellation_app/multiplayer/widgets/practice_view.dart';
import 'package:constellation_app/multiplayer/widgets/scoreboard_view.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

/// Body of the MultiplayerPage: entry, lobby, then the match screen the
/// room's stage calls for
class MultiplayerBody extends StatelessWidget {
  const MultiplayerBody({super.key});

  Future<void> _leave(BuildContext context) async {
    final cubit = context.read<MultiplayerCubit>();
    final room = cubit.state.room;
    if (room == null) return;
    final inGame = room.status == MatchStatus.playing || room.status == MatchStatus.practice;

    // Only the owner can abort the game for everyone; others just leave.
    if (inGame && cubit.state.isHost) {
      switch (await chooseMatchExit(context)) {
        case MatchExit.endGame:
          await cubit.abortMatch();
        case MatchExit.leaveSeat:
          await cubit.leave();
        case MatchExit.stay:
          break;
      }
      return;
    }

    if (!await confirmLeaveMatch(context, midMatch: inGame)) return;
    await cubit.leave();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MultiplayerCubit>();
    return BlocProvider.value(
      value: cubit.game,
      child: BlocConsumer<MultiplayerCubit, MultiplayerState>(
        listenWhen: (previous, current) => previous.stage != current.stage,
        listener: (context, state) {
          switch (state.stage) {
            case MatchStage.practice:
              HapticService.instance.light();
            case MatchStage.playing:
              AudioService.instance.play(GameSound.wheelLand);
              HapticService.instance.heavy();
            case MatchStage.roundOver:
              AudioService.instance.duckMusic(const Duration(seconds: 3));
              AudioService.instance.play(GameSound.roundComplete);
              HapticService.instance.success();
            case MatchStage.finished:
              AudioService.instance.play(GameSound.gameWin);
            default:
              break;
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: state.room == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _leave(context);
            },
            child: GradientBackground(
              child: Stack(
                children: [
                  const Positioned.fill(child: StarDecoration(starCount: 100, starSize: 2)),
                  SafeArea(child: _content(context, state)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, MultiplayerState state) {
    if (state.connection != MultiplayerConnection.inRoom) return const MatchEntryView();
    if (state.room == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
    }
    void onLeave() => _leave(context);
    return switch (state.stage!) {
      MatchStage.lobby => LobbyView(state: state, onLeave: onLeave),
      MatchStage.practice => PracticeView(mp: state, onLeave: onLeave),
      MatchStage.intro => MatchIntroView(mp: state),
      MatchStage.playing || MatchStage.roundOver => MatchPlayView(mp: state, onLeave: onLeave),
      MatchStage.scoreboard || MatchStage.finished => ScoreboardView(mp: state, onLeave: onLeave),
    };
  }
}
