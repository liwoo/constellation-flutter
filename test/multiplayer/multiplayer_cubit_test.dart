import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/multiplayer/cubit/multiplayer_cubit.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/category_service.dart';

import 'fake_match_backend.dart';

/// Star ids that spell a real answer for the category on the board
List<int> spellable(GameState state) {
  final words = CategoryDictionary.instance.getWordsForCategoryAndLetter(state.category, state.currentLetter!);
  for (final word in words) {
    final w = word.toUpperCase();
    if (!RegExp(r'^[A-Z]+$').hasMatch(w)) continue;
    final ids = <int>[];
    for (final c in w.split('')) {
      final node = state.letters.where((l) => l.letter == c && l.id < ShootingStarConfig.letterId).firstOrNull;
      if (node == null || (ids.isNotEmpty && ids.last == node.id)) break;
      ids.add(node.id);
    }
    if (ids.length == w.length) return ids;
  }
  throw StateError('Nothing spellable for ${state.category}');
}

/// Answer the category on [game]'s board (or put it off if the board
/// can't spell one with taps alone)
Future<bool> answerCategory(WidgetTester tester, GameCubit game) async {
  if (game.state.phase == GamePhase.categoryReveal) game.onCategoryRevealed();
  final List<int> ids;
  try {
    ids = spellable(game.state);
  } on StateError {
    game.skipMatchCategory();
    return false;
  }
  for (final id in ids) {
    game.selectLetter(id);
  }
  game.submitWord();
  await tester.pump(const Duration(seconds: 3)); // Celebration, on to the next
  return true;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CategoryService.instance.init();
  });

  late FakeServer server;
  MultiplayerCubit seat(String uid) => MultiplayerCubit(backend: () => FakeMatchBackend(server, uid));

  /// Let room updates and clock ticks land
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 260));
    }
  }

  /// Move the server clock (and let every seat see it)
  Future<void> advance(WidgetTester tester, int ms) async {
    server.now += ms;
    await settle(tester);
  }

  setUp(() => server = FakeServer());

  /// Spell the shared warm-up word on a seat's practice board and submit it
  Future<void> passPractice(WidgetTester tester, MultiplayerCubit seat) async {
    final word = seat.state.room!.setup!.practiceWord;
    for (final c in word.split('')) {
      final node = seat.game.state.letters.firstWhere((l) => l.letter == c);
      seat.game.selectLetter(node.id);
    }
    seat.game.submitWord();
    await settle(tester);
  }

  /// Host deals, both warm up, host starts the scored rounds
  Future<void> startMatch(WidgetTester tester, MultiplayerCubit host, List<MultiplayerCubit> all) async {
    await host.startMatch();
    await settle(tester);
    for (final seat in all) {
      await passPractice(tester, seat);
    }
    await host.startScoring();
    await settle(tester);
  }

  test('the host deals 8 rounds of distinct letters, five answerable categories each', () {
    final setup = MultiplayerCubit.dealMatch(Random(1));
    expect(setup.rounds, hasLength(MultiplayerConfig.rounds));
    expect(setup.rounds.map((r) => r.letter).toSet(), hasLength(MultiplayerConfig.rounds));
    for (final round in setup.rounds) {
      expect(round.letter, isNot('X'));
      expect(round.categories, hasLength(GameState.categoriesPerLetter));
      for (final category in round.categories) {
        expect(
          CategoryDictionary.instance.categoryHasWordsForLetter(category, round.letter),
          isTrue,
          reason: '$category / ${round.letter}',
        );
      }
    }
  });

  testWidgets('friends join the lobby; only the host can start, and needs company', (tester) async {
    final ana = seat('ana');
    final ben = seat('ben');

    await ana.createRoom('Ana');
    await settle(tester);
    final code = ana.state.room!.code;
    expect(ana.state.stage, MatchStage.lobby);
    expect(ana.state.isHost, isTrue);
    expect(ana.state.room!.canStart, isFalse, reason: 'alone');

    await ben.joinRoom(code, 'Ben');
    await settle(tester);
    expect(ana.state.room!.players.keys, containsAll(['ana', 'ben']));
    expect(ben.state.isHost, isFalse);

    await ben.startMatch(); // Not his to start
    await settle(tester);
    expect(ana.state.stage, MatchStage.lobby);

    await ana.startMatch();
    await settle(tester);
    // The warm-up comes first, not the scored rounds
    expect(ana.state.stage, MatchStage.practice);
    expect(ben.state.stage, MatchStage.practice);

    // Too late to join now
    final cy = seat('cy');
    await cy.joinRoom(code, 'Cy');
    expect(cy.state.error, contains('already started'));

    // Only the host can start scoring, and only once everyone's warmed up
    await passPractice(tester, ana);
    expect(ana.state.room!.canStartScoring, isFalse, reason: 'Ben not ready yet');
    await ana.startScoring(); // No-op while Ben's warming up
    await settle(tester);
    expect(ana.state.stage, MatchStage.practice);

    await passPractice(tester, ben);
    expect(ana.state.room!.canStartScoring, isTrue);
    await ben.startScoring(); // Not his to start
    await settle(tester);
    expect(ana.state.stage, MatchStage.practice);

    await ana.startScoring();
    await settle(tester);
    expect(ana.state.stage, MatchStage.intro);
    expect(ben.state.stage, MatchStage.intro);

    await ana.close();
    await ben.close();
    await cy.close();
  });

  testWidgets('a lobby seats six', (tester) async {
    final host = seat('p0');
    await host.createRoom('P0');
    await settle(tester);
    final code = host.state.room!.code;
    final others = [for (var i = 1; i <= MultiplayerConfig.maxPlayers; i++) seat('p$i')];
    for (final (i, p) in others.indexed) {
      await p.joinRoom(code, 'P${i + 1}');
    }
    await settle(tester);
    expect(host.state.room!.players, hasLength(MultiplayerConfig.maxPlayers));
    expect(others.last.state.connection, MultiplayerConnection.idle);
    expect(others.last.state.error, contains('full'));

    await host.close();
    for (final p in others) {
      await p.close();
    }
  });

  testWidgets('a round: same board for both, first to finish ends it, scores tallied', (tester) async {
    final ana = seat('ana');
    final ben = seat('ben');
    await ana.createRoom('Ana');
    await settle(tester);
    await ben.joinRoom(ana.state.room!.code, 'Ben');
    await settle(tester);
    await startMatch(tester, ana, [ana, ben]);

    // Intro over: both boards come up on the same letter and stars
    await advance(tester, MatchTiming.introMs);
    expect(ana.state.stage, MatchStage.playing);
    expect(ana.game.state.isMatch, isTrue);
    expect(ana.game.state.currentLetter, ana.state.room!.setup!.rounds.first.letter);
    ana.game.onCategoryRevealed();
    ben.game.onCategoryRevealed();
    List<Object> board(GameState s) => [for (final l in s.letters) (l.id, l.position)];
    expect(board(ana.game.state), board(ben.game.state));

    // Ben gets one answer in; Ana answers everything
    expect(await answerCategory(tester, ben.game), isTrue);
    await settle(tester);
    expect(ana.state.room!.progress(0)['ben'], 1, reason: 'Ana sees Ben\'s progress live');

    var guard = 0;
    while (ana.game.state.isPlaying && guard++ < 20) {
      await answerCategory(tester, ana.game);
    }
    await settle(tester);

    // Ana's last answer ended the round for both of them
    final room = ana.state.room!;
    expect(room.ends[0]!.by, 'ana');
    expect(ana.state.stage, MatchStage.roundOver);
    expect(ben.state.stage, MatchStage.roundOver);
    expect(ben.game.state.isPlaying, isFalse, reason: 'Ben\'s board froze');

    final points = MatchScoring.roundPoints(room, 0);
    expect(points['ana'], greaterThan(0));
    expect(points['ben'], greaterThan(0));
    expect(MatchScoring.totals(room), points);

    // Then the scoreboard, for 30 seconds, then round 2
    await advance(tester, MatchTiming.roundOverMs);
    expect(ben.state.stage, MatchStage.scoreboard);
    expect(ben.state.secondsToStart, MultiplayerConfig.scoreboardSeconds);
    await advance(tester, MatchTiming.scoreboardMs);
    expect(ben.state.stage, MatchStage.playing);
    expect(ben.state.room!.round, 1);
    expect(ben.game.state.matchRound!.number, 2);
    expect(ben.game.state.currentLetter, ben.state.room!.setup!.rounds[1].letter);

    await ana.close();
    await ben.close();
  });

  testWidgets('nobody finishing: the clock ends the round', (tester) async {
    final ana = seat('ana');
    final ben = seat('ben');
    await ana.createRoom('Ana');
    await settle(tester);
    await ben.joinRoom(ana.state.room!.code, 'Ben');
    await settle(tester);
    await startMatch(tester, ana, [ana, ben]);

    await advance(tester, MatchTiming.introMs + MatchTiming.roundMs);
    expect(ana.state.room!.ends[0], isNotNull);
    expect(ana.state.room!.ends[0]!.by, isNull);
    expect(ben.state.stage, MatchStage.roundOver);

    await ana.close();
    await ben.close();
  });

  testWidgets('only the host can abort, and it jumps to the final scores', (tester) async {
    final ana = seat('ana');
    final ben = seat('ben');
    await ana.createRoom('Ana');
    await settle(tester);
    await ben.joinRoom(ana.state.room!.code, 'Ben');
    await settle(tester);
    await startMatch(tester, ana, [ana, ben]);
    await advance(tester, MatchTiming.introMs);
    expect(ana.state.stage, MatchStage.playing);

    // A guest can't end the game for everyone
    await ben.abortMatch();
    await settle(tester);
    expect(ana.state.stage, MatchStage.playing);

    // The host can - straight to the final standings
    await ana.abortMatch();
    await settle(tester);
    expect(ana.state.stage, MatchStage.finished);
    expect(ben.state.stage, MatchStage.finished);
    expect(ana.game.state.isPlaying, isFalse, reason: 'boards froze');

    await ana.close();
    await ben.close();
  });

  testWidgets('leaving the lobby frees the seat; the next player hosts', (tester) async {
    final ana = seat('ana');
    final ben = seat('ben');
    await ana.createRoom('Ana');
    await settle(tester);
    await ben.joinRoom(ana.state.room!.code, 'Ben');
    await settle(tester);

    await ana.leave();
    await settle(tester);
    expect(ben.state.room!.players.keys, ['ben']);
    expect(ben.state.isHost, isTrue);

    await ana.close();
    await ben.close();
  });
}
