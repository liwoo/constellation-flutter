import 'package:flutter/material.dart';
import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/game/widgets/alpha_quest_body.dart';

/// {@template alpha_quest_page}
/// Alpha Quest game mode - complete all 26 letters
/// {@endtemplate}
class AlphaQuestPage extends StatelessWidget {
  /// {@macro alpha_quest_page}
  const AlphaQuestPage({super.key});

  /// The static route for AlphaQuestPage
  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(builder: (_) => const AlphaQuestPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AlphaQuestCubit(),
      child: const Scaffold(
        body: AlphaQuestView(),
      ),
    );
  }
}

/// {@template alpha_quest_view}
/// Displays the Body of AlphaQuestView
/// {@endtemplate}
class AlphaQuestView extends StatelessWidget {
  /// {@macro alpha_quest_view}
  const AlphaQuestView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlphaQuestBody();
  }
}
