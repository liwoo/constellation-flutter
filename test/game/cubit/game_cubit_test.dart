// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/game/widgets/star_shimmer.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/category_service.dart';
import 'package:constellation_app/shared/services/storage_service.dart';

/// Ids of the letter stars that spell [word] on the current board
List<int> idsFor(GameCubit cubit, String word) => word
    .split('')
    .map((c) => cubit.state.letters.firstWhere((l) => l.letter == c).id)
    .toList();

/// Practice cubit sitting on the first category, ready to play
GameCubit playingPractice() {
  final cubit = GameCubit(isPractice: true)..startPractice();
  cubit.onWheelLanded(PracticeConfig.letter);
  cubit.onCategoryRevealed();
  return cubit;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CategoryService.instance.init();
  });

  group('GameCubit practice', () {
    test('starts at the wheel, which is rigged to the scripted letter', () {
      final cubit = GameCubit(isPractice: true)..startPractice();
      expect(cubit.state.phase, GamePhase.spinningWheel);
      expect(cubit.forcedWheelLetter, PracticeConfig.letter);
      expect(GameCubit().forcedWheelLetter, isNull);
    });

    test('plays the scripted categories, shimmering the example word first', () {
      final cubit = playingPractice();
      expect(cubit.state.currentCategories, PracticeConfig.categories);
      expect(cubit.state.phase, GamePhase.playingRound);
      expect(cubit.state.mysteryOrbs, isEmpty);
      // Shimmer paths are real star ids spelling real answers
      expect(cubit.state.previewPaths.length, WordPreviewConfig.wordCount);
      expect(cubit.state.previewPaths.first, idsFor(cubit, 'CAT'));
      final starIds = cubit.state.letters.map((l) => l.id).toSet();
      for (final path in cubit.state.previewPaths) {
        expect(starIds.containsAll(path), isTrue);
        expect(path.length, lessThanOrEqualTo(WordPreviewConfig.maxLetters));
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
      // Whole word is gone in well under a second
      expect(total, lessThan(1000));
    });

    test('accepts the coach example word like the real game would', () {
      final cubit = playingPractice();
      for (final id in idsFor(cubit, 'CAT')) {
        cubit.selectLetter(id);
      }
      cubit.submitWord();
      expect(cubit.state.lastAnswerCorrect, isTrue);
      expect(cubit.state.score, greaterThan(0));
    });

    test('hint path runs through a mystery orb standing in for a letter', () {
      final cubit = playingPractice();
      // Jump to the last practice category, which has one orb
      cubit.emit(cubit.state.copyWith(
        categoryIndex: 4,
        category: PracticeConfig.categories[4],
      ));
      cubit.onCategoryRevealed();
      final orb = cubit.state.mysteryOrbs.single;

      cubit.showGuidedPath('CAKE');
      expect(cubit.state.hintLetterIds, contains(orb.id));
      expect(cubit.state.hintLetterIds.length, 4);
    });
  });

  group('GameCubit pause', () {
    testWidgets('stops the clock and drops any drag; resume picks up', (tester) async {
      final cubit = playingPractice();
      final start = cubit.state.timeRemaining;

      await tester.pump(const Duration(seconds: 3));
      expect(cubit.state.timeRemaining, start - 3);

      cubit.startDrag(const Offset(0.5, 0.5));
      expect(cubit.pauseGame(), isTrue);
      expect(cubit.state.isPaused, isTrue);
      expect(cubit.state.isDragging, isFalse);

      await tester.pump(const Duration(seconds: 10));
      expect(cubit.state.timeRemaining, start - 3);

      cubit.resumeFromPause();
      await tester.pump(const Duration(seconds: 2));
      expect(cubit.state.timeRemaining, start - 5);
      await cubit.close();
    });

    testWidgets('a paid hint freezes while paused instead of expiring', (tester) async {
      final cubit = playingPractice();
      expect(cubit.useHint(), isTrue);
      cubit.pauseGame();

      await tester.pump(const Duration(seconds: 30));
      expect(cubit.state.hintWord, isNotNull);
      expect(cubit.state.hintAnimationIndex, 0);

      cubit.resumeFromPause();
      await tester.pump(const Duration(seconds: 30));
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
      final cubit = playingPractice();
      cubit.pauseGame();
      cubit.restart();
      expect(cubit.state.isPaused, isFalse);
      expect(cubit.state.phase, GamePhase.spinningWheel);
      expect(cubit.state.timeRemaining, GameConfig.startingTime);
      expect(cubit.state.score, 0);
    });

    testWidgets('restarting mid-celebration does not leak into the new run', (tester) async {
      final cubit = playingPractice();
      for (final c in 'CAT'.split('')) {
        cubit.selectLetter(cubit.state.letters.firstWhere((l) => l.letter == c).id);
      }
      cubit.submitWord();
      cubit.pauseGame();
      cubit.restart();

      await tester.pump(const Duration(seconds: 3));
      expect(cubit.state.phase, GamePhase.spinningWheel);
      expect(cubit.state.categoryIndex, 0);
      await cubit.close();
    });

    testWidgets('a held clock (tutorial / modal) does not tick', (tester) async {
      final cubit = playingPractice();
      final start = cubit.state.timeRemaining;
      cubit.setTimerHeld(true);
      await tester.pump(const Duration(seconds: 5));
      expect(cubit.state.timeRemaining, start);
      expect(cubit.state.isPaused, isFalse);
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
      // Points and bonus time earned mid-letter are replayed on resume
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
      final cubit = playingPractice();
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
      final cubit = playingPractice();
      await tester.pump(const Duration(seconds: HintConfig.stuckAfterSeconds - 1));
      expect(cubit.state.isStuck, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(cubit.state.isStuck, isTrue);

      // Paused seconds don't count
      final paused = playingPractice()..pauseGame();
      await tester.pump(const Duration(seconds: HintConfig.stuckAfterSeconds + 5));
      expect(paused.state.isStuck, isFalse);
      await cubit.close();
      await paused.close();
    });
  });
}
