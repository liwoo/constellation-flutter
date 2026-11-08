import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/multiplayer/multiplayer.dart';
import 'package:constellation_app/shared/services/category_service.dart';

import 'fake_match_backend.dart';
import 'multiplayer_cubit_test.dart' show answerCategory;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CategoryService.instance.init();
  });

  testWidgets('every screen of a match lays out on a phone', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final server = FakeServer();
    final ana = MultiplayerCubit(backend: () => FakeMatchBackend(server, 'ana'));
    final ben = MultiplayerCubit(backend: () => FakeMatchBackend(server, 'ben'));

    Future<void> settle() async {
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 260));
      }
    }

    Future<void> advance(int ms) async {
      server.now += ms;
      await settle();
    }

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(
        value: ana,
        child: const Scaffold(body: MultiplayerBody()),
      ),
    ));
    await settle();
    expect(find.text('CREATE GAME'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Ana');
    await tester.tap(find.text('CREATE GAME'));
    await settle();
    expect(find.text('LOBBY'), findsOneWidget);
    expect(find.text('WAITING FOR PLAYERS'), findsOneWidget);

    await ben.joinRoom(ana.state.room!.code, 'Ben');
    await settle();
    expect(find.text('Ben'), findsOneWidget);

    // Spell the shared warm-up word to mark a seat ready
    Future<void> warmUp(MultiplayerCubit seat) async {
      final word = seat.state.room!.setup!.practiceWord;
      for (final c in word.split('')) {
        final node = seat.game.state.letters.firstWhere((l) => l.letter == c);
        seat.game.selectLetter(node.id);
      }
      seat.game.submitWord();
      await settle();
    }

    // Host starts: the warm-up comes first, not the scored rounds
    await tester.tap(find.text('START GAME'));
    await settle();
    expect(find.text('WARM-UP'), findsOneWidget);

    await warmUp(ben);
    await warmUp(ana);
    expect(find.text("YOU'RE READY"), findsOneWidget);

    // Everyone's ready: the host kicks off scoring
    await tester.tap(find.text('START GAME'));
    await settle();
    expect(find.text('ROUND 1 OF 8'), findsOneWidget);

    await advance(MatchTiming.introMs);
    expect(find.text('ROUND 1/8'), findsOneWidget);
    // Category spins in (on chained timers - pump in small steps)
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(ana.game.state.phase, GamePhase.playingRound);
    expect(find.text('LATER'), findsNothing, reason: 'no skipping in multiplayer');

    var guard = 0;
    while (ana.game.state.isPlaying && guard++ < 20) {
      await answerCategory(tester, ana.game);
      await tester.pump(const Duration(seconds: 2));
    }
    await settle();
    expect(find.text('ROUND OVER'), findsOneWidget);
    expect(find.text('You finished first!'), findsOneWidget);

    await advance(MatchTiming.roundOverMs);
    expect(find.text('ROUND 1 RESULTS'), findsOneWidget);
    expect(find.textContaining('ROUND 2 OF 8 IN'), findsOneWidget);

    // Skip to the end of the match
    for (var round = 1; round < 8; round++) {
      await advance(MatchTiming.scoreboardMs + MatchTiming.roundMs);
      await advance(MatchTiming.roundOverMs);
    }
    expect(find.text('FINAL STANDINGS'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);

    await tester.tap(find.text('PLAY AGAIN'));
    await settle();
    expect(find.text('LOBBY'), findsOneWidget);

    await ana.close();
    await ben.close();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
