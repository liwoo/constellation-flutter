// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/game/widgets/coach_targets.dart';
import 'package:constellation_app/practice/cubit/cubit.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/category_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CategoryService.instance.init();
  });

  /// Let the tutorial hear the game's state stream
  Future<void> settle(WidgetTester tester) => tester.pump(Duration.zero);

  /// Wait out the opening star shimmer (one word is at most maxLetters stars)
  Future<void> waitForPreview(WidgetTester tester) => tester.pump(Duration(
        milliseconds: WordPreviewConfig.totalMs(
              List.filled(WordPreviewConfig.wordCount, List.filled(WordPreviewConfig.maxLetters, 0)),
            ) +
            300,
      ));

  testWidgets('walks a new player through the first category', (tester) async {
    final game = GameCubit(isPractice: true)..startPractice();
    final tutorial = TutorialCubit(game);
    await settle(tester);

    expect(tutorial.state.step, TutorialStep.welcome);
    tutorial.next();
    expect(tutorial.state.step, TutorialStep.spinWheel);
    // Action steps can't be clicked past
    tutorial.next();
    expect(tutorial.state.step, TutorialStep.spinWheel);

    game.onWheelLanded(PracticeConfig.letter);
    await settle(tester);
    expect(tutorial.state.step, isNull);

    game.onCategoryRevealed();
    await settle(tester);
    expect(tutorial.state.step, isNull, reason: 'coach waits for the star shimmer');
    await waitForPreview(tester);

    for (final step in [
      TutorialStep.previewWords,
      TutorialStep.startLetter,
      TutorialStep.category,
      TutorialStep.timer,
    ]) {
      expect(tutorial.state.step, step);
      tutorial.next();
    }

    // Drag: the example word's path is shown, and the clock is held
    expect(tutorial.state.step, TutorialStep.drag);
    expect(game.state.hintWord, PracticeConfig.exampleWords[0]);
    final time = game.state.timeRemaining;
    await tester.pump(const Duration(seconds: 4));
    expect(game.state.timeRemaining, time);

    for (final c in 'CAT'.split('')) {
      game.selectLetter(game.state.letters.firstWhere((l) => l.letter == c).id);
    }
    await settle(tester);
    expect(tutorial.state.step, TutorialStep.submit);

    game.submitWord();
    await settle(tester);
    expect(tutorial.state.step, isNull);
    expect(game.state.lastAnswerCorrect, isTrue);

    // Free play: the clock runs again
    final afterSubmit = game.state.timeRemaining;
    await tester.pump(const Duration(seconds: 2));
    expect(game.state.timeRemaining, afterSubmit - 2);

    await tutorial.close();
    await game.close();
  });

  testWidgets('a first miss is explained, pointing at DEL', (tester) async {
    final game = GameCubit(isPractice: true)..startPractice();
    final tutorial = TutorialCubit(game)..dismiss();
    // Jump straight into play with the tutorial otherwise done
    tutorial.emit(TutorialState(completed: TutorialStep.values.toSet()..remove(TutorialStep.wrongAnswer)));
    game.onWheelLanded(PracticeConfig.letter);
    game.onCategoryRevealed();
    await settle(tester);

    final c = game.state.letters.firstWhere((l) => l.letter == 'C').id;
    game.selectLetter(c);
    game.repeatLastLetter();
    game.submitWord();
    await settle(tester);

    expect(tutorial.state.step, TutorialStep.wrongAnswer);
    expect(TutorialStep.wrongAnswer.target, CoachTarget.del);
    await tutorial.close();
    await game.close();
  });

  testWidgets('skipping the tutorial releases the clock for good', (tester) async {
    final game = GameCubit(isPractice: true)..startPractice();
    final tutorial = TutorialCubit(game);
    await settle(tester);
    tutorial.dismiss();

    game.onWheelLanded(PracticeConfig.letter);
    game.onCategoryRevealed();
    await waitForPreview(tester);
    expect(tutorial.state.step, isNull);

    final time = game.state.timeRemaining;
    await tester.pump(const Duration(seconds: 2));
    expect(game.state.timeRemaining, time - 2);
    await tutorial.close();
    await game.close();
  });

  testWidgets('restarting practice replays the tutorial', (tester) async {
    final game = GameCubit(isPractice: true)..startPractice();
    final tutorial = TutorialCubit(game);
    await settle(tester);
    tutorial.next();
    game.onWheelLanded(PracticeConfig.letter);
    await settle(tester);

    game.restart();
    await settle(tester);
    expect(tutorial.state.step, TutorialStep.welcome);
    await tutorial.close();
    await game.close();
  });
}
