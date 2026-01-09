/// Word length multipliers for scoring
class WordMultipliers {
  const WordMultipliers._();

  /// Get multiplier based on word length
  static int getMultiplier(int wordLength) {
    if (wordLength >= 20) return 8;
    if (wordLength >= 15) return 4;
    if (wordLength >= 10) return 2;
    return 1;
  }

  /// Multiplier brackets for UI display
  static const Map<String, int> brackets = {
    '1-9 letters': 1,
    '10-14 letters': 2,
    '15-19 letters': 4,
    '20+ letters': 8,
  };
}
