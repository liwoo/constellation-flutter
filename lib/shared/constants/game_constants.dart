// Game configuration constants for Alpha Quest mode
// All magic numbers extracted for easy tuning and balancing

/// Starting game configuration
class GameConfig {
  const GameConfig._();

  /// Initial time at game start (seconds)
  static const int startingTime = 250;

  /// Number of hints player starts with
  static const int startingHints = 3;

  /// Number of categories to complete per letter
  static const int categoriesPerLetter = 5;

  /// Total letters to complete (A-Y, no X)
  static const int totalLetters = 25;
}

/// Scoring configuration
class ScoringConfig {
  const ScoringConfig._();

  /// Bonus points per space used (multi-word answers)
  static const int spacePointsBonus = 5;

  /// Bonus points per x2 repeat used
  static const int repeatPointsBonus = 3;

  /// Bonus points for long words (>= 7 letters)
  static const int longWordBonus = 10;

  /// Minimum letters for long word bonus
  static const int longWordThreshold = 7;

  /// Bonus points for medium words (>= 5 letters)
  static const int mediumWordBonus = 5;

  /// Minimum letters for medium word bonus
  static const int mediumWordThreshold = 5;

  /// Score multiplier from mystery orb (1.5x)
  static const double mysteryScoreMultiplier = 1.5;
}

/// Time bonus and penalty configuration
class TimeConfig {
  const TimeConfig._();

  /// Time bonus per space used (seconds)
  static const int spaceTimeBonus = 10;

  /// Time bonus for pure connection (seconds)
  static const int pureConnectionBonus = 15;

  /// Time penalty for wrong answer (seconds)
  static const int wrongAnswerPenalty = 5;

  /// Time penalty for selecting invalid letter (seconds)
  static const int invalidSelectionPenalty = 2;

  /// Time bonus for completing all 5 categories for a letter (seconds)
  static const int letterCompletionBonus = 15;

  /// Time bonus from mystery orb (seconds)
  static const int mysteryTimeBonus = 10;

  /// Time penalty from mystery orb (seconds)
  static const int mysteryTimePenalty = 5;

  /// Time cost to use a hint (seconds)
  static const int hintTimeCost = 10;

  /// Minimum time required to use a hint (seconds)
  static const int minTimeForHint = 15;
}

/// Clutch time multiplier configuration
/// Rewards players who complete rounds with low time remaining
class ClutchConfig {
  const ClutchConfig._();

  /// Time threshold for 2x multiplier (seconds)
  static const int doubleMultiplierThreshold = 10;

  /// Time threshold for 1.5x multiplier (seconds)
  static const int halfMultiplierThreshold = 20;

  /// Multiplier when time <= doubleMultiplierThreshold
  static const double doubleMultiplier = 2.0;

  /// Multiplier when time <= halfMultiplierThreshold (but > doubleMultiplierThreshold)
  static const double halfMultiplier = 1.5;

  /// Default multiplier (no bonus)
  static const double noMultiplier = 1.0;

  /// Get the appropriate clutch multiplier for the given remaining time
  static double getMultiplier(int timeRemaining) {
    if (timeRemaining <= doubleMultiplierThreshold) return doubleMultiplier;
    if (timeRemaining <= halfMultiplierThreshold) return halfMultiplier;
    return noMultiplier;
  }
}

/// Hint configuration - shorter words in early rounds
class HintConfig {
  const HintConfig._();

  /// Get max word length for hints based on round
  /// Earlier rounds get shorter, easier hints
  static int getMaxHintLength(int round) {
    if (round <= 5) return 5;   // Very short words only
    if (round <= 10) return 7;  // Short to medium
    if (round <= 15) return 9;  // Medium length
    if (round <= 20) return 11; // Longer allowed
    return 999;                  // No limit for final rounds
  }

  /// Round threshold below which we always pick the shortest word
  static const int preferShortestRoundThreshold = 10;
}

/// Animation duration configuration (milliseconds)
class AnimationConfig {
  const AnimationConfig._();

  /// Delay after correct answer before transitioning (normal)
  static const int normalCelebrationDelay = 800;

  /// Delay after pure connection for dramatic animation
  static const int pureConnectionCelebrationDelay = 2200;

  /// Duration of pure connection celebration animation
  static const int pureConnectionAnimationDuration = 2500;

  /// Haptic burst delay 1 for pure connection
  static const int hapticBurstDelay1 = 150;

  /// Haptic burst delay 2 for pure connection
  static const int hapticBurstDelay2 = 300;

  /// Delay per letter when revealing hint
  static const int hintLetterRevealDelay = 400;

  /// Extra time after all hint letters revealed
  static const int hintCompletionBuffer = 800;

  /// Duration to display mystery orb outcome
  static const int mysteryOutcomeDisplayDuration = 2000;
}

/// Hit detection and drag configuration
class HitDetectionConfig {
  const HitDetectionConfig._();

  /// Inner radius for direct hit detection (relative units 0-1)
  static const double innerHitRadius = 0.05;

  /// Outer radius for dwell detection (relative units 0-1)
  static const double outerHitRadius = 0.08;

  /// Time required to dwell on a letter for selection (seconds)
  static const int dwellTimeSeconds = 1;

  /// Velocity threshold for pass-through detection (relative units/second)
  /// Lower = must slow down more to trigger selection
  static const double passThroughVelocity = 0.15;
}

/// Mystery orb configuration
class MysteryOrbConfig {
  const MysteryOrbConfig._();

  /// Probability weights for mystery outcomes (must sum to 100)
  static const int timeBonusProbability = 40;
  static const int scoreMultiplierProbability = 15;
  static const int freeHintProbability = 10;
  static const int timePenaltyProbability = 25;
  static const int scrambleLettersProbability = 10;

  /// Number of consecutive penalties before guaranteed reward
  static const int pityThreshold = 2;

  /// Reward bonus for early rounds (percentage points)
  static const int earlyRoundRewardBonus = 10; // Rounds 1-5
  static const int midRoundRewardBonus = 5; // Rounds 6-10

  /// Get mystery orb count based on round number
  static int getOrbCount(int round) {
    if (round <= 5) return 0;
    if (round <= 10) return 1;
    if (round <= 15) return 2;
    if (round <= 20) return 3;
    if (round <= 23) return 4;
    return 5; // Rounds 24-25
  }
}

/// Letter difficulty configuration
class DifficultyConfig {
  const DifficultyConfig._();

  /// Maximum letter difficulty allowed by round
  /// (excludes harder letters from early rounds)
  static int getMaxDifficulty(int round) {
    if (round <= 5) return 3; // No U, V, Y, Q, Z
    if (round <= 10) return 4; // No Q, Z
    return 5; // All letters allowed
  }

  /// Maximum preferred difficulty for weighted selection
  static int getMaxPreferredDifficulty(int round) {
    if (round <= 5) return 2;
    if (round <= 10) return 3;
    if (round <= 15) return 4;
    return 5;
  }

  /// Letter difficulty levels (1 = easiest, 5 = hardest)
  static const Map<String, int> letterDifficulty = {
    // Difficulty 1: Very common starting letters
    'A': 1, 'B': 1, 'C': 1, 'S': 1, 'M': 1, 'P': 1,
    // Difficulty 2: Common starting letters
    'D': 2, 'F': 2, 'G': 2, 'H': 2, 'L': 2, 'R': 2, 'T': 2,
    // Difficulty 3: Moderately common
    'E': 3, 'I': 3, 'J': 3, 'K': 3, 'N': 3, 'O': 3, 'W': 3,
    // Difficulty 4: Less common
    'U': 4, 'V': 4, 'Y': 4,
    // Difficulty 5: Rare starting letters (X excluded from game)
    'Q': 5, 'Z': 5,
  };
}

/// Layout configuration for letter constellation
class LayoutConfig {
  const LayoutConfig._();

  /// Grid padding from edges (relative 0-1)
  static const double gridPaddingX = 0.08;
  static const double gridPaddingY = 0.08;

  /// Available height for letter grid
  static const double gridAvailableHeight = 0.84;

  /// Jitter amount for letter positions (as fraction of cell size)
  static const double positionJitter = 0.20;

  /// QWERTY layout configuration
  static const double qwertyPaddingX = 0.05;
  static const double qwertyBottomPadding = 0.18;
  static const double qwertyRowSpacing = 0.20;
  static const double qwertyRow2Indent = 0.04;
  static const double qwertyRow3Indent = 0.12;
}
