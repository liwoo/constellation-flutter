import 'package:flutter/material.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/game_body.dart';
import 'package:constellation_app/practice/cubit/cubit.dart';
import 'package:constellation_app/practice/widgets/coach_mark_overlay.dart';

/// {@template practice_page}
/// Practice: one scripted letter of the real game, with coach marks that
/// pause to show which buttons to press.
/// {@endtemplate}
class PracticePage extends StatelessWidget {
  /// {@macro practice_page}
  const PracticePage({super.key});

  /// The static route for PracticePage
  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(builder: (_) => const PracticePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameCubit(isPractice: true)..startPractice(),
      child: BlocProvider(
        create: (context) => TutorialCubit(context.read<GameCubit>()),
        child: const Scaffold(
          body: PracticeView(),
        ),
      ),
    );
  }
}

/// {@template practice_view}
/// The real game screen with the practice coach on top
/// {@endtemplate}
class PracticeView extends StatelessWidget {
  /// {@macro practice_view}
  const PracticeView({super.key});

  @override
  Widget build(BuildContext context) {
    return GameBody(
      tutorialOverlayBuilder: (targets) => CoachMarkOverlay(targets: targets),
    );
  }
}
