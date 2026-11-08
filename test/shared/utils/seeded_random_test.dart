import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/shared/utils/seeded_random.dart';

void main() {
  group('SeededRandom', () {
    test('matches the reference Mulberry32 (Math.imul in JavaScript)', () {
      // node: mulberry32(seed) -> first five outputs, as unsigned ints
      const reference = {
        0: [1144304738, 1416247, 958946056, 627933444, 2007157716],
        42: [2581720956, 1925393290, 3661312704, 2876485805, 750819978],
        123456789: [1107202814, 4169434471, 3372958138, 885470128, 1301683845],
        4294967295: [3850105811, 813802916, 3073704848, 4054706436, 3630262831],
      };
      for (final MapEntry(key: seed, value: expected) in reference.entries) {
        final random = SeededRandom(seed);
        expect([for (var i = 0; i < 5; i++) random.nextUint32()], expected, reason: 'seed $seed');
      }
    });

    test('same seed, same shuffle', () {
      final a = List.generate(30, (i) => i)..shuffle(SeededRandom(7));
      final b = List.generate(30, (i) => i)..shuffle(SeededRandom(7));
      final c = List.generate(30, (i) => i)..shuffle(SeededRandom(8));
      expect(a, b);
      expect(a, isNot(c));
    });

    test('stays in range', () {
      final random = SeededRandom(99);
      for (var i = 0; i < 1000; i++) {
        expect(random.nextInt(7), inInclusiveRange(0, 6));
        expect(random.nextDouble(), inInclusiveRange(0.0, 1.0));
      }
      expect(() => random.nextInt(0), throwsRangeError);
    });
  });
}
