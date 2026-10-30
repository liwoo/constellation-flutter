import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/practice/cubit/cubit.dart';
import 'package:constellation_app/shared/constants/constants.dart';

/// Where [letter]'s star sits on the lesson board
Offset at(PracticeCubit cubit, String letter) =>
    cubit.state.letters.firstWhere((s) => s.letter == letter).position;

/// Touch the first star, then slide-and-hold onto each following one
Future<void> spell(WidgetTester tester, PracticeCubit cubit, String letters) async {
  cubit.startDrag(at(cubit, letters[0]));
  for (final l in letters.substring(1).split('')) {
    cubit.updateDrag(at(cubit, l));
    await tester.pump(const Duration(milliseconds: HitDetectionConfig.dwellTimeMs + 50));
  }
  cubit.endDrag();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lessons cover connect, the click, spaces and double letters', () {
    expect(practiceLessons.map((l) => l.word), ['HI', 'CAT', 'ICE CREAM', 'BALL']);
    // Each board has a star for every letter it asks for
    for (final lesson in practiceLessons) {
      for (final c in lesson.word.replaceAll(' ', '').split('')) {
        expect(lesson.stars.keys, contains(c));
      }
    }
  });

  testWidgets('connect: touch, slide, hold, GO - then on to the next lesson', (tester) async {
    final cubit = PracticeCubit();
    expect(cubit.state.cue, PracticeCue.touchStar);
    expect(cubit.state.nextLetter, 'H');

    cubit.startDrag(at(cubit, 'H'));
    expect(cubit.state.builtWord, 'H');
    expect(cubit.state.cue, PracticeCue.slideAndHold);
    expect(cubit.state.nextLetter, 'I');

    cubit.updateDrag(at(cubit, 'I'));
    await tester.pump(const Duration(milliseconds: HitDetectionConfig.dwellTimeMs + 50));
    cubit.endDrag();
    expect(cubit.state.builtWord, 'HI');
    expect(cubit.state.cue, PracticeCue.go);

    cubit.submit();
    expect(cubit.state.phase, PracticePhase.lessonComplete);
    await tester.pump(PracticeCubit.lessonCelebration);
    expect(cubit.state.lessonIndex, 1);
    expect(cubit.state.phase, PracticePhase.playing);
    expect(cubit.state.builtWord, isEmpty);
    await cubit.close();
  });

  testWidgets('lifting before the click is caught and explained', (tester) async {
    final cubit = PracticeCubit()..startLesson(1); // CAT
    cubit.startDrag(at(cubit, 'C'));
    cubit.updateDrag(at(cubit, 'A'));
    await tester.pump(const Duration(milliseconds: 300));
    cubit.endDrag();

    expect(cubit.state.builtWord, 'C');
    expect(cubit.state.releasedEarly, isTrue);

    cubit.clearSelection();
    await spell(tester, cubit, 'CAT');
    expect(cubit.state.builtWord, 'CAT');
    expect(cubit.state.releasedEarly, isFalse);
    await cubit.close();
  });

  testWidgets('two words: space is cued between them', (tester) async {
    final cubit = PracticeCubit()..startLesson(2); // ICE CREAM
    await spell(tester, cubit, 'ICE');
    expect(cubit.state.cue, PracticeCue.space);
    cubit.insertSpace();
    expect(cubit.state.cue, PracticeCue.touchStar);
    expect(cubit.state.nextLetter, 'C');
    await spell(tester, cubit, 'CREAM');
    expect(cubit.state.builtWord, 'ICE CREAM');
    expect(cubit.state.cue, PracticeCue.go);
    await cubit.close();
  });

  testWidgets('double letters: x2 is cued for the repeat', (tester) async {
    final cubit = PracticeCubit()..startLesson(3); // BALL
    await spell(tester, cubit, 'BAL');
    expect(cubit.state.cue, PracticeCue.repeat);
    cubit.repeatLastLetter();
    expect(cubit.state.builtWord, 'BALL');
    expect(cubit.state.cue, PracticeCue.go);

    cubit.submit();
    await tester.pump(PracticeCubit.lessonCelebration);
    expect(cubit.state.phase, PracticePhase.finished);
    await cubit.close();
  });

  testWidgets('a wrong star cues DEL; GO too soon is caught', (tester) async {
    final cubit = PracticeCubit()..startLesson(1); // CAT, with a decoy O
    await spell(tester, cubit, 'CO');
    expect(cubit.state.cue, PracticeCue.delete);
    cubit.clearSelection();
    expect(cubit.state.builtWord, isEmpty);
    expect(cubit.state.cue, PracticeCue.touchStar);

    await spell(tester, cubit, 'CA');
    cubit.submit();
    expect(cubit.state.submittedTooSoon, isTrue);
    expect(cubit.state.phase, PracticePhase.playing);
    await cubit.close();
  });
}
