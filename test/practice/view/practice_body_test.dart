import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/practice/cubit/cubit.dart';
import 'package:constellation_app/practice/widgets/practice_body.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';

Offset at(PracticeCubit cubit, String letter) =>
    cubit.state.letters.firstWhere((s) => s.letter == letter).position;

/// Dwell rings drawn in the target word at the top (not on the board)
Iterable<DwellRingPainter> topRings(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<DwellRingPainter>();

void main() {
  testWidgets('the letter being held is ringed in the word at the top, as in the game',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final cubit = PracticeCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: PracticeBody()),
        ),
      ),
    );
    // Let the opening "show me" finish
    await tester.pump(const Duration(seconds: 3));
    expect(topRings(tester), isEmpty);

    // Touch H, slide onto I and hold
    cubit.startDrag(at(cubit, 'H'));
    cubit.updateDrag(at(cubit, 'I'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: HitDetectionConfig.dwellTimeMs ~/ 2));
    final ring = topRings(tester).single;
    expect(ring.color, AppColors.accentCyan);
    expect(ring.progress, closeTo(0.5, 0.1));

    // Clicked in - the ring gives way to the filled slot
    await tester.pump(const Duration(milliseconds: HitDetectionConfig.dwellTimeMs));
    expect(cubit.state.builtWord, 'HI');
    expect(topRings(tester), isEmpty);

    cubit.endDrag();
    await cubit.close();
    await tester.pump(const Duration(seconds: 2));
  });
}
