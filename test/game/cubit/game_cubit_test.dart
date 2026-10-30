// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/game/widgets/star_shimmer.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/category_service.dart';
import 'package:constellation_app/shared/services/storage_service.dart';

/// Ids of the letter stars that spell [word] on the current board
List<int> idsFor(GameCubit cubit, String word) => word
    .split('')
    .map((c) => cubit.state.letters.firstWhere((l) => l.letter == c).id)
    .toList();

/// A real game sitting on letter C / ANIMALS, ready to play
GameCubit playingRound({int letterRound = 1, String category = 'ANIMALS'}) {
  final cubit = GameCubit()..startGame();
  cubit.emit(cubit.state.copyWith(letterRound: letterRound));
  cubit.onWheelLanded('C');
  cubit.emit(cubit.state.copyWith(
    category: category,
    currentCategories: [category, 'COLORS', 'BEVERAGES', 'TRANSPORTATION', 'CLOTHING'],
  ));
  cubit.onCategoryRevealed();
  return cubit;
}

/// Send a shooting star in, forced to carry [letter] so tests can spell with it
GameCubit withShootingStar(GameCubit cubit, String letter) {
  expect(cubit.spawnShootingStar(), isTrue);
  cubit.emit(cubit.state.copyWith(
    letters: [
      for (final l in cubit.state.letters)
        l.id == ShootingStarConfig.letterId
            ? LetterNode(id: l.id, letter: letter, points: l.points, position: l.position)
            : l,
    ],
    shootingStar: ShootingStar(
      letter: letter,
      from: cubit.state.shootingStar!.from,
      secondsLeft: ShootingStarConfig.lifetimeSeconds,
    ),
  ));
  return cubit;
}

/// Tap out [ids] and submit
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

  group('GameCubit round start', () {
    test('a few real answers are traced across the stars', () {
      final cubit = playingRound();
      final starIds = cubit.state.letters.map((l) => l.id).toSet();
      expect(cubit.state.previewPaths.length, WordPreviewConfig.wordCount);
      for (final path in cubit.state.previewPaths) {
        expect(starIds.containsAll(path), isTrue);
        expect(path.length, lessThanOrEqualTo(WordPreviewConfig.maxLetters));
        expect(path.first, idsFor(cubit, 'C').single);
      }
    });

    test('shimmer timeline: stars light in order, then the word fades away', () {
      const path = [1, 2, 3];
      const step = WordPreviewConfig.starStepMs;
      final early = ShimmerFrame.at([path], step * 0.5)!;
      expect(early.brightness(0), greaterThan(0));
      expect(early.brightness(1), 0);

      final held = ShimmerFrame.at([path], 3.0 * step + 10)!;
      expect([0, 1, 2].map(held.brightness), everyElement(1.0));

      final total = WordPreviewConfig.totalMs([path]).toDouble();
      expect(ShimmerFrame.at([path], total - 1)!.fade, lessThan(0.05));
      expect(ShimmerFrame.at([path], total + 1), isNull);
      expect(total, lessThan(1000), reason: 'gone in well under a second');
    });

    test('hint paths run through mystery orbs standing in for letters', () {
      // Round 6+ has an orb; with letter C it replaces a vowel
      final cubit = playingRound(letterRound: 8, category: 'FOOD & DRINK');
      final orb = cubit.state.mysteryOrbs.single;
      final ids = {...cubit.state.letters.map((l) => l.id), orb.id};

      expect(cubit.useHint(), isTrue);
      final word = cubit.state.hintWord!;
      expect(cubit.state.hintLetterIds.length, word.replaceAll(' ', '').length);
      expect(ids.containsAll(cubit.state.hintLetterIds), isTrue);
      if (word.contains(orb.replacedLetter)) {
        expect(cubit.state.hintLetterIds, contains(orb.id));
      }
    });
  });

  group('GameCubit dragging', () {
    testWidgets('holding still on a star still clicks it in', (tester) async {
      final cubit = playingRound();
      Offset at(String l) => cubit.state.letters.firstWhere((s) => s.letter == l).position;

      cubit.startDrag(at('C'));
      cubit.updateDrag(at('A')); // one move event, then perfectly still
      await tester.pump(const Duration(milliseconds: HitDetectionConfig.dwellTimeMs - 100));
      expect(cubit.state.selectedLetterIds, idsFor(cubit, 'C'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(cubit.state.selectedLetterIds, idsFor(cubit, 'CA'));
      await cubit.close();
    });
  });

  group('GameCubit pause', () {
    testWidgets('the clock keeps ticking while paused (no free thinking time)', (tester) async {
      final cubit = playingRound();
      final start = cubit.state.timeRemaining;

      cubit.startDrag(const Offset(0.5, 0.5));
      expect(cubit.pauseGame(), isTrue);
      expect(cubit.state.isPaused, isTrue);
      expect(cubit.state.isDragging, isFalse);

      await tester.pump(const Duration(seconds: 5));
      expect(cubit.state.timeRemaining, start - 5);

      cubit.resumeFromPause();
      expect(cubit.state.isPaused, isFalse);
      await cubit.close();
    });

    testWidgets('a paid hint freezes behind the pause screen', (tester) async {
      final cubit = playingRound();
      expect(cubit.useHint(), isTrue);
      cubit.pauseGame();

      await tester.pump(const Duration(seconds: 10));
      expect(cubit.state.hintWord, isNotNull);
      expect(cubit.state.hintAnimationIndex, 0);

      cubit.resumeFromPause();
      await tester.pump(const Duration(seconds: 10));
      expect(cubit.state.hintWord, isNull);
      await cubit.close();
    });

    test('is only offered while a letter is in play', () {
      final cubit = GameCubit();
      expect(cubit.canPause, isFalse); // start screen
      cubit.startGame();
      expect(cubit.canPause, isTrue); // wheel
      cubit.emit(cubit.state.copyWith(phase: GamePhase.letterComplete));
      expect(cubit.pauseGame(), isFalse);
    });

    test('restart begins a brand new run', () {
      final cubit = playingRound();
      cubit.pauseGame();
      cubit.restart();
      expect(cubit.state.isPaused, isFalse);
      expect(cubit.state.phase, GamePhase.spinningWheel);
      expect(cubit.state.timeRemaining, GameConfig.startingTime);
      expect(cubit.state.score, 0);
    });

    testWidgets('restarting mid-celebration does not leak into the new run', (tester) async {
      final cubit = playingRound();
      for (final id in idsFor(cubit, 'CAT')) {
        cubit.selectLetter(id);
      }
      cubit.submitWord();
      expect(cubit.state.lastAnswerCorrect, isTrue);
      cubit.pauseGame();
      cubit.restart();

      await tester.pump(const Duration(seconds: 3));
      expect(cubit.state.phase, GamePhase.spinningWheel);
      expect(cubit.state.categoryIndex, 0);
      await cubit.close();
    });

    testWidgets('a blocking modal can hold the clock', (tester) async {
      final cubit = playingRound();
      final start = cubit.state.timeRemaining;
      cubit.setTimerHeld(true);
      await tester.pump(const Duration(seconds: 5));
      expect(cubit.state.timeRemaining, start);
      cubit.setTimerHeld(false);
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.timeRemaining, start - 1);
      await cubit.close();
    });
  });

  group('GameCubit quitting mid-letter', () {
    testWidgets('saves a checkpoint that refunds no time, hints or points', (tester) async {
      final cubit = GameCubit()..startGame();
      // Second letter of a run: a resume checkpoint exists
      cubit.emit(cubit.state.copyWith(
        completedLetters: ['A'],
        letterRound: 2,
        score: 100,
      ));
      cubit.onWheelLanded('B');
      cubit.onCategoryRevealed();
      final startTime = cubit.state.timeRemaining;
      final startHints = cubit.state.hintsRemaining;

      await tester.pump(const Duration(seconds: 30));
      expect(cubit.useHint(), isTrue);
      // Points earned mid-letter are replayed on resume, so not banked
      cubit.emit(cubit.state.copyWith(score: 160));
      cubit.quitToMenu();

      final saved = await tester.runAsync(StorageService.instance.loadGameProgress);
      expect(saved!.letterRound, 2);
      expect(saved.timeRemaining, startTime - 30 - TimeConfig.hintTimeCost);
      expect(saved.hintsRemaining, startHints - 1);
      expect(saved.score, 100);

      // Gaining time then quitting can't bank it either
      cubit.emit(cubit.state.copyWith(timeRemaining: startTime + 50));
      cubit.quitToMenu();
      final again = await tester.runAsync(StorageService.instance.loadGameProgress);
      expect(again!.timeRemaining, startTime);
      await cubit.close();
    });
  });

  group('GameCubit stuck detection', () {
    testWidgets('pulses the hint after repeated misses, not before', (tester) async {
      final cubit = playingRound();
      final c = idsFor(cubit, 'C').single;

      for (var i = 0; i < HintConfig.stuckAfterWrongAttempts; i++) {
        expect(cubit.state.isStuck, isFalse);
        cubit.selectLetter(c);
        cubit.repeatLastLetter(); // "CC" - never an answer
        cubit.submitWord();
      }
      expect(cubit.state.isStuck, isTrue);

      cubit.useHint();
      expect(cubit.state.isStuck, isFalse);
      await cubit.close();
    });

    testWidgets('pulses the hint after a long time on one category', (tester) async {
      final cubit = playingRound();
      await tester.pump(const Duration(seconds: HintConfig.stuckAfterSeconds - 1));
      expect(cubit.state.isStuck, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.isStuck, isTrue);
      await cubit.close();
    });
  });

  group('GameCubit shooting star', () {
    const starId = ShootingStarConfig.letterId;

    test('streaks in trailing a bonus letter from one of the answers', () {
      final cubit = playingRound();
      expect(cubit.spawnShootingStar(), isTrue);

      final star = cubit.state.shootingStar!;
      final node = cubit.state.letters.singleWhere((l) => l.id == starId);
      expect(node.letter, star.letter);
      expect(star.secondsLeft, ShootingStarConfig.lifetimeSeconds);
      // It lands on the board, clear of the other stars
      expect(node.position.dx, inInclusiveRange(0.0, 1.0));
      expect(node.position.dy, inInclusiveRange(0.0, 1.0));
      final answers = CategoryDictionary.instance
          .getWordsForCategoryAndLetter('ANIMALS', 'C')
          .map((w) => w.toUpperCase().replaceAll(' ', ''));
      expect(answers.any((w) => w.substring(1).contains(star.letter)), isTrue);

      // Only one at a time
      expect(cubit.spawnShootingStar(), isFalse);
    });

    testWidgets('connecting it into the word doubles its points', (tester) async {
      final plain = playingRound();
      submit(plain, idsFor(plain, 'CAT'));
      final base = plain.state.score;
      expect(base, greaterThan(0));

      final cubit = withShootingStar(playingRound(), 'A');
      submit(cubit, [...idsFor(cubit, 'C'), starId, ...idsFor(cubit, 'T')]);
      final bonus = base < ShootingStarConfig.minBonusPoints
          ? ShootingStarConfig.minBonusPoints
          : base * (ShootingStarConfig.scoreMultiplier - 1);
      expect(cubit.state.lastAnswerCorrect, isTrue);
      expect(cubit.state.score, base + bonus);
      expect(cubit.state.lastShootingStarBonus, bonus);

      await tester.pump(const Duration(seconds: 3));
      await plain.close();
      await cubit.close();
    });

    testWidgets('a word without it scores normally', (tester) async {
      final plain = playingRound();
      submit(plain, idsFor(plain, 'CAT'));

      final cubit = withShootingStar(playingRound(), 'A');
      submit(cubit, idsFor(cubit, 'CAT'));
      expect(cubit.state.score, plain.state.score);
      expect(cubit.state.lastShootingStarBonus, isNull);

      await tester.pump(const Duration(seconds: 3));
      await plain.close();
      await cubit.close();
    });

    testWidgets('burns out if nobody catches it', (tester) async {
      final cubit = withShootingStar(playingRound(), 'A');
      await tester.pump(const Duration(seconds: ShootingStarConfig.lifetimeSeconds - 1));
      expect(cubit.state.shootingStar!.isFading, isTrue);
      expect(cubit.state.letters.any((l) => l.id == starId), isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.shootingStar, isNull);
      expect(cubit.state.letters.any((l) => l.id == starId), isFalse);
      await cubit.close();
    });

    testWidgets('never burns out of a word that is using it', (tester) async {
      final cubit = withShootingStar(playingRound(), 'A');
      cubit.selectLetter(idsFor(cubit, 'C').single);
      cubit.selectLetter(starId);
      await tester.pump(const Duration(seconds: ShootingStarConfig.lifetimeSeconds + 3));
      expect(cubit.state.shootingStar, isNotNull);
      expect(cubit.state.currentSelection, 'CA');

      // Dropped from the word - now it goes
      cubit.clearSelection();
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.shootingStar, isNull);
      await cubit.close();
    });

    test('the next category starts without it', () {
      final cubit = withShootingStar(playingRound(), 'A');
      cubit.emit(cubit.state.copyWith(phase: GamePhase.categoryReveal));
      cubit.onCategoryRevealed();
      expect(cubit.state.shootingStar, isNull);
      expect(cubit.state.letters.any((l) => l.id == starId), isFalse);
    });

    test('hints never route through it', () {
      final cubit = withShootingStar(playingRound(), 'A');
      expect(cubit.useHint(), isTrue);
      expect(cubit.state.hintLetterIds, isNot(contains(starId)));
    });
  });

  group('GameCubit lives', () {
    /// Run the clock down to zero
    Future<void> runOutOfTime(WidgetTester tester, GameCubit cubit) async {
      cubit.emit(cubit.state.copyWith(timeRemaining: 1));
      await tester.pump(const Duration(seconds: 2));
    }

    testWidgets("running out of time stops at time's up, not game over", (tester) async {
      final cubit = playingRound();
      expect(cubit.state.lives, LivesConfig.startingLives);
      await runOutOfTime(tester, cubit);
      expect(cubit.state.phase, GamePhase.outOfTime);
      expect(cubit.state.isPlaying, isFalse);

      // The clock is stopped while deciding
      await tester.pump(const Duration(seconds: 5));
      expect(cubit.state.phase, GamePhase.outOfTime);
      await cubit.close();
    });

    testWidgets('a life replays the letter from its first category', (tester) async {
      final cubit = playingRound();
      final startTime = cubit.state.timeRemaining;
      final startHints = cubit.state.hintsRemaining;
      submit(cubit, idsFor(cubit, 'CAT'));
      await tester.pump(const Duration(seconds: 1)); // On to category 2
      expect(cubit.state.categoryIndex, 1);
      expect(cubit.state.score, greaterThan(0));
      cubit.useHint();

      await runOutOfTime(tester, cubit);
      expect(cubit.useLife(), isTrue);
      expect(cubit.state.lives, LivesConfig.startingLives - 1);
      expect(cubit.state.phase, GamePhase.categoryReveal);
      expect(cubit.state.currentLetter, 'C');
      expect(cubit.state.categoryIndex, 0);
      expect(cubit.state.category, 'ANIMALS');
      expect(cubit.state.completedWords, isEmpty);
      expect(cubit.state.score, 0);
      expect(cubit.state.timeRemaining, startTime);
      expect(cubit.state.hintsRemaining, startHints);

      // And the clock runs again
      await tester.pump(const Duration(seconds: 2));
      expect(cubit.state.timeRemaining, startTime - 2);
      await cubit.close();
    });

    testWidgets('a replay never starts with less than the minimum time', (tester) async {
      final cubit = GameCubit()..startGame();
      cubit.emit(cubit.state.copyWith(timeRemaining: 12));
      cubit.onWheelLanded('C');
      cubit.onCategoryRevealed();
      await runOutOfTime(tester, cubit);
      expect(cubit.replayTime, LivesConfig.minRestartTime);
      cubit.useLife();
      expect(cubit.state.timeRemaining, LivesConfig.minRestartTime);
      await cubit.close();
    });

    testWidgets('out of lives: an ad or a purchase brings one back', (tester) async {
      final cubit = playingRound();
      cubit.emit(cubit.state.copyWith(lives: 0));
      await runOutOfTime(tester, cubit);
      expect(cubit.useLife(), isFalse);
      expect(cubit.state.phase, GamePhase.outOfTime);

      cubit.addLives(LivesConfig.adReward, source: 'ad');
      expect(cubit.state.lives, 1);
      expect(cubit.useLife(), isTrue);
      expect(cubit.state.lives, 0);

      await runOutOfTime(tester, cubit);
      cubit.addLives(10, source: 'lives_10');
      expect(cubit.state.lives, 10);
      await cubit.close();
    });

    testWidgets('giving up ends the run', (tester) async {
      final cubit = playingRound();
      await runOutOfTime(tester, cubit);
      cubit.giveUp();
      expect(cubit.state.phase, GamePhase.gameOver);
      expect(cubit.state.isWinner, isFalse);
      expect(cubit.useLife(), isFalse); // Too late now
      await cubit.close();
    });

    testWidgets('stars can still buy 60s on the spot', (tester) async {
      final cubit = playingRound();
      cubit.emit(cubit.state.copyWith(stars: StarConfig.continueCost));
      await runOutOfTime(tester, cubit);
      expect(cubit.continueWithStars(), isTrue);
      expect(cubit.state.phase, GamePhase.playingRound);
      expect(cubit.state.timeRemaining, 60);
      expect(cubit.state.lives, LivesConfig.startingLives);
      await cubit.close();
    });

    testWidgets("closing the app at time's up costs the life it would", (tester) async {
      final cubit = GameCubit()..startGame();
      cubit.emit(cubit.state.copyWith(completedLetters: ['A'], letterRound: 2, score: 100));
      cubit.onWheelLanded('B');
      cubit.onCategoryRevealed();
      final startTime = cubit.state.timeRemaining;
      await runOutOfTime(tester, cubit);

      var saved = await tester.runAsync<SavedGameProgress?>(StorageService.instance.loadGameProgress);
      expect(saved!.lives, LivesConfig.startingLives - 1);
      expect(saved.timeRemaining, startTime);
      expect(saved.score, 100);

      // With no lives left there's nothing to come back to
      cubit.useLife();
      cubit.emit(cubit.state.copyWith(lives: 0));
      await runOutOfTime(tester, cubit);
      saved = await tester.runAsync<SavedGameProgress?>(StorageService.instance.loadGameProgress);
      expect(saved, isNull);

      // ...until a life is earned
      cubit.addLives(1, source: 'ad');
      saved = await tester.runAsync<SavedGameProgress?>(StorageService.instance.loadGameProgress);
      expect(saved!.lives, 0);
      await cubit.close();
    });

    test('every new run starts with a full set', () {
      final cubit = playingRound();
      cubit.emit(cubit.state.copyWith(lives: 0));
      cubit.restart();
      expect(cubit.state.lives, LivesConfig.startingLives);
    });
  });
}
