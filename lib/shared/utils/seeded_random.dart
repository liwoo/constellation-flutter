import 'dart:math';

/// A [Random] that produces the same sequence for the same seed on every
/// platform - native and web alike - so multiplayer boards laid out from a
/// shared seed come out identical for every player.
///
/// Mulberry32, written with 32-bit-safe arithmetic (web ints are doubles,
/// so a plain 32x32 multiply would lose precision).
class SeededRandom implements Random {
  SeededRandom(int seed) : _state = seed & _mask;

  static const int _mask = 0xFFFFFFFF;

  int _state;

  /// Next 32-bit unsigned value
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >>> 7), t | 61)) & _mask)) & _mask;
    return (t ^ (t >>> 14)) & _mask;
  }

  /// 32-bit multiply keeping the low 32 bits, exact on every platform
  static int _imul(int a, int b) {
    final aHi = (a >>> 16) & 0xFFFF;
    final aLo = a & 0xFFFF;
    final bHi = (b >>> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    final cross = ((aHi * bLo + aLo * bHi) & 0xFFFF) * 0x10000;
    return (aLo * bLo + cross) & _mask;
  }

  @override
  int nextInt(int max) {
    if (max <= 0 || max > 0x100000000) {
      throw RangeError.range(max, 1, 0x100000000, 'max');
    }
    return nextUint32() % max;
  }

  @override
  double nextDouble() => nextUint32() / 4294967296.0;

  @override
  bool nextBool() => (nextUint32() >>> 31) == 1;
}
