import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/multiplayer/cubit/multiplayer_cubit.dart';
import 'package:constellation_app/multiplayer/widgets/multiplayer_body.dart';

/// {@template multiplayer_page}
/// Realtime multiplayer: open a room, invite friends, race through the
/// same rounds. [joinCode] comes from an invite link.
/// {@endtemplate}
class MultiplayerPage extends StatelessWidget {
  /// {@macro multiplayer_page}
  const MultiplayerPage({super.key, this.joinCode});

  final String? joinCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MultiplayerCubit()..init(joinCode: joinCode),
      child: const Scaffold(
        body: MultiplayerBody(),
      ),
    );
  }
}
