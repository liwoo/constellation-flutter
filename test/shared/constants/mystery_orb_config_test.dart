import 'dart:math';

import 'package:constellation_app/shared/constants/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MysteryOrbConfig.orbsForBoard', () {
    /// Share of 2000 boards at [round] that carry any orbs
    double shareWithOrbs(int round, {bool isMatch = false}) {
      final random = Random(7);
      var withOrbs = 0;
      for (var i = 0; i < 2000; i++) {
        if (MysteryOrbConfig.orbsForBoard(round, random, isMatch: isMatch) > 0) withOrbs++;
      }
      return withOrbs / 2000;
    }

    test('no orbs in the first five rounds', () {
      for (var round = 1; round <= 5; round++) {
        expect(shareWithOrbs(round), 0);
        expect(shareWithOrbs(round, isMatch: true), 0);
      }
    });

    test('most solo boards have none, and never more than two', () {
      expect(shareWithOrbs(10), closeTo(MysteryOrbConfig.chancePercent / 100, 0.04));
      final random = Random(1);
      for (var round = 1; round <= 30; round++) {
        expect(MysteryOrbConfig.orbsForBoard(round, random), lessThanOrEqualTo(2));
      }
    });

    test('match boards are rarer still, with at most one orb', () {
      expect(shareWithOrbs(22, isMatch: true), closeTo(MysteryOrbConfig.matchChancePercent / 100, 0.03));
      expect(shareWithOrbs(22, isMatch: true), lessThan(shareWithOrbs(22)));
      final random = Random(1);
      for (var round = 1; round <= 30; round++) {
        expect(MysteryOrbConfig.orbsForBoard(round, random, isMatch: true), lessThanOrEqualTo(1));
      }
    });

    test('the same seed deals the same orbs, so match players agree', () {
      final a = Random(99);
      final b = Random(99);
      for (var i = 0; i < 50; i++) {
        expect(
          MysteryOrbConfig.orbsForBoard(22, a, isMatch: true),
          MysteryOrbConfig.orbsForBoard(22, b, isMatch: true),
        );
      }
    });
  });
}
