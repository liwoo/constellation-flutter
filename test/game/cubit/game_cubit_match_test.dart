// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/category_service.dart';

const categories = ['ANIMALS', 'COLORS', 'BEVERAGES', 'TRANSPORTATION', 'CLOTHING'];

MatchRound matchRound({int number = 1, int seed = 42}) => MatchRound(
      number: number,
      totalRounds: MultiplayerConfig.rounds,
      letter: 'C',
      categories: categories,
      seed: seed,
      endsAt: DateTime.now().add(const Duration(minutes: 3)),
    );

/// A match board for [round], first category revealed
GameCubit inMatch(
  MatchRound round, {
  void Function(MatchSubmission answer)? onAnswer,
  void Function()? onFinished,
}) {
  final cubit = GameCubit(onMatchAnswer: onAnswer, onMatchFinished: onFinished)..startMatchRound(round);
  cubit.onCategoryRevealed();
  return cubit;
}

/// A late match round whose first board happens to carry a mystery orb
/// (they're rare, so try seeds until one deals one)
MatchRound roundWithOrb() {
  for (var seed = 42; seed < 2000; seed++) {
    final round = matchRound(number: 6, seed: seed);
    if (inMatch(round).state.mysteryOrbs.isNotEmpty) return round;
  }
  throw StateError('no seed dealt a mystery orb');
}

/// Everything that makes up a board, comparable
List<Object> board(GameState state) => [
      for (final l in state.letters) (l.id, l.letter, l.position),
      for (final o in state.mysteryOrbs) (o.id, o.replacedLetter, o.position),
      state.category,
    ];

/// Star ids that spell a real answer for the current category (tapped, so
/// no doubled letters), or null if the board can't spell one
List<int>? spellable(GameState state) {
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
  return null;
}

void submit(GameCubit cubit, List<int> ids) {
  for (final id in ids) {
    cubit.selectLetter(id);
  }
  cubit.submitWord();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CategoryService.instance.init();
  });

  group('GameCubit match play', () {
    test('every player gets the same board, orbs and shooting star', () {
      final round = roundWithOrb();
      final ana = inMatch(round);
      final ben = inMatch(round);
      expect(ana.state.mysteryOrbs, hasLength(MysteryOrbConfig.matchMaxOrbs));
      expect(board(ana.state), board(ben.state));
      expect(ana.state.previewPaths, ben.state.previewPaths);

      expect(ana.spawnShootingStar(), isTrue);
      expect(ben.spawnShootingStar(), isTrue);
      expect(ana.state.shootingStar!.letter, ben.state.shootingStar!.letter);
      expect(ana.state.shootingStar!.from, ben.state.shootingStar!.from);
      expect(board(ana.state), board(ben.state));
    });

    test('mystery orbs are rare in a match', () {
      var boards = 0;
      var withOrbs = 0;
      for (var seed = 0; seed < 200; seed++) {
        final cubit = inMatch(matchRound(number: MultiplayerConfig.rounds, seed: seed));
        boards++;
        if (cubit.state.mysteryOrbs.isNotEmpty) withOrbs++;
        expect(cubit.state.mysteryOrbs.length, lessThanOrEqualTo(MysteryOrbConfig.matchMaxOrbs));
      }
      expect(withOrbs / boards, lessThan(0.2), reason: '$withOrbs of $boards boards');
    });

    test('each category and each match gets its own board', () {
      final a = inMatch(matchRound());
      final b = inMatch(matchRound(seed: 43));
      expect(board(a.state), isNot(board(b.state)));
    });

    test('putting a category off brings the next one up, and it comes back on the same board', () {
      final ana = inMatch(matchRound());
      final first = board(ana.state);

      expect(ana.skipMatchCategory(), isTrue);
      expect(ana.state.phase, GamePhase.categoryReveal);
      expect(ana.state.category, categories[1]);
      expect(ana.state.currentCategories.last, categories[0]);

      // Ana keeps putting categories off until ANIMALS comes round again;
      // Ben plays it first. Same board.
      final ben = inMatch(matchRound());
      ana.onCategoryRevealed();
      for (var i = 1; i < categories.length; i++) {
        expect(ana.skipMatchCategory(), isTrue);
        ana.onCategoryRevealed();
      }
      expect(ana.state.category, categories[0]);
      expect(board(ana.state), first);
      expect(board(ben.state), first);
    });

    test('the last category left cannot be put off', () {
      final cubit = inMatch(matchRound());
      cubit.emit(cubit.state.copyWith(categoryIndex: GameState.categoriesPerLetter - 1));
      expect(cubit.skipMatchCategory(), isFalse);
    });

    testWidgets('answers report their dealt category; the shared clock never moves', (tester) async {
      final answers = <MatchSubmission>[];
      final cubit = inMatch(matchRound(), onAnswer: answers.add);
      final time = cubit.state.timeRemaining;

      // Wrong answers cost nothing
      final others = cubit.state.letters.where((l) => l.letter != 'C').toList().reversed.take(6);
      submit(cubit, [cubit.state.letters.firstWhere((l) => l.letter == 'C').id, ...others.map((l) => l.id)]);
      expect(cubit.state.lastAnswerCorrect, isFalse);
      expect(cubit.state.timeRemaining, time);

      // Put ANIMALS off, answer COLORS - reported as category 1
      cubit.skipMatchCategory();
      cubit.onCategoryRevealed();
      submit(cubit, spellable(cubit.state)!);
      expect(cubit.state.lastAnswerCorrect, isTrue);
      expect(answers.single.category, 1);
      expect(answers.single.points, greaterThan(0));
      expect(answers.single.isAutocorrected, isFalse);
      expect(cubit.state.timeRemaining, lessThanOrEqualTo(time), reason: 'no time bonus');

      await tester.pump(const Duration(seconds: 3));
      await cubit.close();
    });

    testWidgets('answering all five finishes the round', (tester) async {
      var finished = 0;
      final answered = <int>[];
      final cubit = inMatch(
        matchRound(),
        onAnswer: (a) => answered.add(a.category),
        onFinished: () => finished++,
      );
      for (var i = 0; i < GameState.categoriesPerLetter; i++) {
        if (i > 0) cubit.onCategoryRevealed();
        submit(cubit, spellable(cubit.state)!);
        expect(cubit.state.lastAnswerCorrect, isTrue, reason: cubit.state.category);
        await tester.pump(const Duration(seconds: 3));
      }
      expect(answered, [0, 1, 2, 3, 4]);
      expect(finished, 1);
      expect(cubit.state.isPlaying, isFalse);
      await cubit.close();
    });

    test('mystery orbs are plain wildcards - no surprises', () {
      final cubit = inMatch(roundWithOrb());
      final orb = cubit.state.mysteryOrbs.first;
      cubit.selectLetter(cubit.state.letters.firstWhere((l) => l.letter == 'C').id);
      cubit.startDrag(orb.position);
      expect(cubit.state.lastMysteryOutcome, isNull);
    });

    test('no pausing a match', () {
      final cubit = inMatch(matchRound());
      expect(cubit.pauseGame(), isFalse);
    });

    testWidgets('a round that ends freezes the board', (tester) async {
      final cubit = inMatch(matchRound());
      cubit.endMatchRound();
      expect(cubit.state.isPlaying, isFalse);
      final time = cubit.state.timeRemaining;
      await tester.pump(const Duration(seconds: 3));
      expect(cubit.state.timeRemaining, time);
      await cubit.close();
    });
  });

  group('GameCubit autocorrect', () {
    /// Submit [typed] as though spelled on the board ('*' for a mystery
    /// orb, ' ' for the space button) on the first category, ANIMALS
    MatchSubmission? spell(String typed) {
      MatchSubmission? answer;
      final cubit = inMatch(matchRound(), onAnswer: (a) => answer = a);
      cubit.emit(cubit.state.copyWith(committedWord: typed, spaceUsageCount: ' '.allMatches(typed).length));
      cubit.submitWord();
      if (answer == null) expect(cubit.state.lastAnswerCorrect, isFalse, reason: typed);
      return answer;
    }

    test('a word in the list counts in full', () {
      final answer = spell('CHEETAH')!;
      expect(answer.word, 'CHEETAH');
      expect(answer.spelled, 'CHEETAH');
      expect(answer.isAutocorrected, isFalse);
    });

    test('a slip in a long word is corrected for a share of the points', () {
      final full = spell('CHEETAH')!.points;
      final answer = spell('CHEETAHH')!;
      expect(answer.word, 'CHEETAH');
      expect(answer.spelled, 'CHEETAHH');
      expect(answer.isAutocorrected, isTrue);
      expect(answer.points, (full * AutocorrectConfig.pointsShare).round());
      expect(spell('CHIMPANZE')?.word, 'CHIMPANZEE');
    });

    test('short words are never corrected - one letter off is another word', () {
      expect(spell('CAZ'), isNull);
      expect(spell('CTA'), isNull);
    });

    test('a long word more than a slip away is wrong', () {
      expect(spell('CHEEEEEE'), isNull);
      expect(spell('CHATTAH'), isNull);
    });

    test('the round letter is not a slip', () {
      expect(spell('HEETAH'), isNull);
      expect(spell('SHEETAH'), isNull);
    });

    test('mystery orbs stand for one letter, not anything at all', () {
      expect(spell('CHEE*AH')?.isAutocorrected, isFalse);
      expect(spell('CHEE*AH')?.word, 'CHEETAH');
      expect(spell('CH*ETAHH')?.isAutocorrected, isTrue);
      expect(spell('C*ZZZZ'), isNull);
      expect(spell('C*ZZZZZZZ'), isNull);
      expect(spell('*ZZZ'), isNull);
    });

    test('a trailing space earns no space bonus', () {
      expect(spell('CHEETAH ')!.points, spell('CHEETAH')!.points);
      expect(spell('CHEETAH ')!.spelled, 'CHEETAH');
    });

    test('the corrected word is called out on the board', () {
      final cubit = inMatch(matchRound());
      cubit.emit(cubit.state.copyWith(committedWord: 'CHEETAHH'));
      cubit.submitWord();
      expect(cubit.state.lastAutocorrectedWord, 'CHEETAH');
    });
  });
}
