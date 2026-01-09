/// Letter point values following Scrabble-like scoring system
class LetterPoints {
  const LetterPoints._();

  static const Map<String, int> values = {
    // 1 point letters
    'A': 1,
    'E': 1,
    'I': 1,
    'O': 1,
    'U': 1,
    'L': 1,
    'N': 1,
    'S': 1,
    'T': 1,
    'R': 1,

    // 2 point letters
    'D': 2,
    'G': 2,

    // 3 point letters
    'B': 3,
    'C': 3,
    'M': 3,
    'P': 3,

    // 4 point letters
    'F': 4,
    'H': 4,
    'V': 4,
    'W': 4,
    'Y': 4,

    // 5 point letters
    'K': 5,

    // 8 point letters
    'J': 8,
    'X': 8,

    // 10 point letters
    'Q': 10,
    'Z': 10,
  };

  /// Get point value for a letter
  static int getPoints(String letter) {
    return values[letter.toUpperCase()] ?? 0;
  }

  /// Calculate letter value with repetition penalty
  /// First use: 100%, Second: 50%, Third: 25%, etc.
  static double getPointsWithPenalty(String letter, int usageCount) {
    final basePoints = getPoints(letter);
    if (usageCount == 0) return basePoints.toDouble();

    // Apply halving penalty for each previous use
    return basePoints / (1 << usageCount); // 1 << n is 2^n
  }
}
