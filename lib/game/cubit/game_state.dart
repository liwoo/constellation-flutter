part of 'game_cubit.dart';

class LetterNode {
  final String letter;
  final int points;
  final Offset position; // Relative position (0.0-1.0)
  final int id;

  const LetterNode({
    required this.letter,
    required this.points,
    required this.position,
    required this.id,
  });
}

/// Types of mystery orb outcomes
enum MysteryOutcome {
  /// +10 seconds time bonus (40% of rewards)
  timeBonus,
  /// 1.5x score multiplier for next word (15% of rewards)
  scoreMultiplier,
  /// Reveal a hint for free (10% of rewards)
  freeHint,
  /// -5 seconds time penalty (25% of penalties)
  timePenalty,
  /// Scramble letter positions (10% of penalties)
  scrambleLetters,
}

/// Model representing a mystery orb in the constellation
/// Acts as a wildcard (blank) that can substitute for any letter
class MysteryOrb {
  final int id;
  final Offset position; // Relative position (0.0-1.0)
  final bool isActive; // Whether the orb is visible and can be activated
  final DateTime? activatedAt; // When it was last activated
  final String replacedLetter; // The letter this blank replaces (for validation)
  final bool effectTriggered; // Whether the reward/penalty effect was already triggered

  const MysteryOrb({
    required this.id,
    required this.position,
    this.isActive = true,
    this.activatedAt,
    this.replacedLetter = '', // Empty means it can be any letter
    this.effectTriggered = false,
  });

  MysteryOrb copyWith({
    int? id,
    Offset? position,
    bool? isActive,
    DateTime? activatedAt,
    bool clearActivatedAt = false,
    String? replacedLetter,
    bool? effectTriggered,
  }) {
    return MysteryOrb(
      id: id ?? this.id,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      activatedAt: clearActivatedAt ? null : (activatedAt ?? this.activatedAt),
      replacedLetter: replacedLetter ?? this.replacedLetter,
      effectTriggered: effectTriggered ?? this.effectTriggered,
    );
  }
}

/// Game phase for Alpha Quest mode
enum GamePhase {
  /// Initial state - show start screen
  notStarted,
  /// Spinning wheel to select letter
  spinningWheel,
  /// Category jackpot animation
  categoryReveal,
  /// Player forming word with constellation
  playingRound,
  /// Letter round complete - celebration screen
  letterComplete,
  /// Game over - win or lose
  gameOver,
}

class GameState extends Equatable {
  const GameState({
    this.letters = const [],
    this.selectedLetterIds = const [],
    this.committedWord = '', // Word segments already locked in
    this.completedWords = const [],
    this.score = 0,
    this.timeRemaining = 250, // Start with 250s
    this.category = '',
    this.difficulty = 2,
    this.isPlaying = false,
    this.isDragging = false,
    this.currentDragPosition,
    // Alpha Quest fields
    this.phase = GamePhase.notStarted,
    this.currentLetter,
    this.completedLetters = const [],
    this.letterRound = 1, // Which letter we're on (1-26)
    this.isWinner = false,
    this.lastAnswerCorrect,
    // Category round fields (5 categories per letter)
    this.currentCategories = const [], // 5 categories for current letter
    this.categoryIndex = 0, // Which category we're on (0-4)
    // Bonus tracking for current word
    this.spaceUsageCount = 0, // Times space button used
    this.repeatUsageCount = 0, // Times x2 button used
    // Score tracking for time bonus
    this.letterRoundStartScore = 0, // Score at start of current letter round
    // Animation feedback
    this.lastTimeBonus, // Time bonus from last correct answer (for animation)
    // Hints system
    this.hintsRemaining = 3, // Player starts with 3 hints
    this.hintWord, // Word currently being shown as hint (internal)
    this.hintLetterIds = const [], // Letter node IDs in order for hint animation
    this.hintAnimationIndex = 0, // Current index in hint animation sequence
    this.usedHintWords = const {}, // Words already shown as hints per category this letter round
    // Predictive highlighting (letters in drag direction)
    this.approachingLetterIds = const [],
    // Pure connection tracking - true if word built in single drag
    this.isPureConnection = false,
    this.showConnectionAnimation = false,
    // Mystery orb system
    this.mysteryOrbs = const [],
    this.consecutivePenalties = 0, // Pity system: reset when reward given
    this.scoreMultiplierActive = false, // 1.5x multiplier for next word
    this.lastMysteryOutcome, // For animation feedback
    this.pendingMysteryOrbId, // Orb being hovered over
    this.mysteryOrbDwellStartTime, // When dwell started on mystery orb
    // Letter dwell progress for visual feedback
    this.pendingLetterId, // Letter currently being dwelled on
    this.letterDwellStartTime, // When dwell started on letter
    this.lastConnectedLetterId, // For "just connected" flash animation
    // Cheat code tracking
    this.skipCheatUsedThisRound = false, // Skip category cheat (once per letter round)
    // Star currency system
    this.stars = 2, // Current star balance (persisted across games)
    this.starsEarnedThisGame = 0, // Stars earned in current game session
    this.lastStarThreshold = 0, // Last score threshold crossed for star award
    this.showStarEarnedAnimation = false, // Trigger star earned animation
  });

  /// Special ID for space character in selectedLetterIds
  static const int spaceId = -1;

  final List<LetterNode> letters;
  final List<int> selectedLetterIds; // Order matters, same id can appear multiple times
  final String committedWord; // Word segments already locked in (with trailing space)
  final List<String> completedWords;
  final int score;
  final int timeRemaining;
  final String category; // Current active category (from currentCategories)
  final int difficulty;
  final bool isPlaying;
  final bool isDragging;
  final Offset? currentDragPosition; // Relative position (0.0-1.0)

  // Alpha Quest fields
  final GamePhase phase;
  final String? currentLetter; // Letter player must start word with
  final List<String> completedLetters; // Letters already completed (A-Z)
  final int letterRound; // Which letter round we're on (1-26)
  final bool isWinner;
  final bool? lastAnswerCorrect; // Feedback for last submission

  // Category round fields
  final List<String> currentCategories; // 5 random categories for current letter
  final int categoryIndex; // Current category index (0-4)

  // Bonus tracking
  final int spaceUsageCount; // Times space button used for current word
  final int repeatUsageCount; // Times x2 button used for current word

  // Score tracking for time bonus calculation
  final int letterRoundStartScore; // Score at start of current letter round

  // Animation feedback
  final int? lastTimeBonus; // Time bonus from last correct answer (for animation)

  // Hints system
  final int hintsRemaining; // Number of hints left
  final String? hintWord; // Word currently being shown as hint (internal)
  final List<int> hintLetterIds; // Letter node IDs in order for hint animation
  final int hintAnimationIndex; // Current index in hint animation sequence
  final Map<String, List<String>> usedHintWords; // Words already shown as hints per category

  // Predictive highlighting - letters in the direction user is dragging
  final List<int> approachingLetterIds;

  // Pure connection tracking - rewards continuous drag word building
  final bool isPureConnection; // True if current word built in single drag
  final bool showConnectionAnimation; // Trigger celebration animation for path

  // Mystery orb system
  final List<MysteryOrb> mysteryOrbs; // 3 mystery orbs in constellation
  final int consecutivePenalties; // Pity timer: guaranteed reward after 2 penalties
  final bool scoreMultiplierActive; // 1.5x score multiplier for next word
  final MysteryOutcome? lastMysteryOutcome; // For animation feedback
  final int? pendingMysteryOrbId; // Orb currently being hovered
  final DateTime? mysteryOrbDwellStartTime; // When dwell started

  // Letter dwell progress tracking for visual feedback
  final int? pendingLetterId; // Letter currently being dwelled on
  final DateTime? letterDwellStartTime; // When dwell started on letter
  final int? lastConnectedLetterId; // For "just connected" flash animation

  // Cheat code tracking
  final bool skipCheatUsedThisRound; // Skip category cheat used this letter round

  // Star currency system
  final int stars; // Current star balance (persisted across games)
  final int starsEarnedThisGame; // Stars earned in current game session
  final int lastStarThreshold; // Last score threshold crossed for star award
  final bool showStarEarnedAnimation; // Trigger star earned animation

  /// Points earned in current letter round
  int get pointsEarnedInRound => score - letterRoundStartScore;

  /// Categories completed for current letter
  int get categoriesCompletedForLetter => categoryIndex;

  /// Total bonus count for current word
  int get totalBonusCount => spaceUsageCount + repeatUsageCount;

  /// Total categories to complete per letter
  static const int categoriesPerLetter = 5;

  /// Wildcard character used for mystery orbs in word patterns
  static const String wildcardChar = '*';

  /// Get the current selection as a string (just the active drag)
  /// Mystery orbs are TRUE WILDCARDS marked with '*' - can be any letter
  String get currentSelection => selectedLetterIds.map((id) {
        if (id == spaceId) return ' ';
        // Mystery orbs are wildcards - marked with '*'
        if (id >= 100) return wildcardChar;
        return letters.firstWhere((l) => l.id == id).letter;
      }).join();

  /// Get the full word being built (committed + current selection)
  String get currentWord => committedWord + currentSelection;

  /// Get selected letter nodes in order (spaces are represented as null)
  /// Mystery orbs return null (they're not LetterNodes but act as wildcards)
  List<LetterNode?> get selectedLetters => selectedLetterIds.map((id) {
        if (id == spaceId) return null; // null represents space
        // Mystery orbs have IDs 100+, return null for them
        if (id >= 100) return null;
        return letters.firstWhere(
          (l) => l.id == id,
          orElse: () => const LetterNode(id: -1, letter: '', points: 0, position: Offset.zero),
        );
      }).toList();

  /// Check if there's any word content (either committed or selected)
  bool get hasWordContent =>
      committedWord.isNotEmpty || selectedLetterIds.isNotEmpty;

  /// Total letters to complete (25, excluding X)
  static const int totalLetters = 25;

  /// Get remaining letters count for Alpha Quest
  int get remainingLettersCount => totalLetters - completedLetters.length;

  /// Get progress percentage (0.0 to 1.0) for Alpha Quest
  double get progress => completedLetters.length / totalLetters.toDouble();

  /// Check if game is over (win or lose)
  bool get isGameOver => phase == GamePhase.gameOver;

  @override
  List<Object?> get props => [
        letters,
        selectedLetterIds,
        committedWord,
        completedWords,
        score,
        timeRemaining,
        category,
        difficulty,
        isPlaying,
        isDragging,
        currentDragPosition,
        phase,
        currentLetter,
        completedLetters,
        letterRound,
        isWinner,
        lastAnswerCorrect,
        currentCategories,
        categoryIndex,
        spaceUsageCount,
        repeatUsageCount,
        letterRoundStartScore,
        lastTimeBonus,
        hintsRemaining,
        hintWord,
        hintLetterIds,
        hintAnimationIndex,
        usedHintWords,
        approachingLetterIds,
        isPureConnection,
        showConnectionAnimation,
        mysteryOrbs,
        consecutivePenalties,
        scoreMultiplierActive,
        lastMysteryOutcome,
        pendingMysteryOrbId,
        mysteryOrbDwellStartTime,
        pendingLetterId,
        letterDwellStartTime,
        lastConnectedLetterId,
        skipCheatUsedThisRound,
        stars,
        starsEarnedThisGame,
        lastStarThreshold,
        showStarEarnedAnimation,
      ];

  GameState copyWith({
    List<LetterNode>? letters,
    List<int>? selectedLetterIds,
    String? committedWord,
    List<String>? completedWords,
    int? score,
    int? timeRemaining,
    String? category,
    int? difficulty,
    bool? isPlaying,
    bool? isDragging,
    Offset? currentDragPosition,
    bool clearDragPosition = false,
    GamePhase? phase,
    String? currentLetter,
    bool clearCurrentLetter = false,
    List<String>? completedLetters,
    int? letterRound,
    bool? isWinner,
    bool? lastAnswerCorrect,
    bool clearLastAnswerCorrect = false,
    List<String>? currentCategories,
    int? categoryIndex,
    int? spaceUsageCount,
    int? repeatUsageCount,
    int? letterRoundStartScore,
    int? lastTimeBonus,
    bool clearLastTimeBonus = false,
    int? hintsRemaining,
    String? hintWord,
    bool clearHintWord = false,
    List<int>? hintLetterIds,
    int? hintAnimationIndex,
    Map<String, List<String>>? usedHintWords,
    bool clearUsedHintWords = false,
    List<int>? approachingLetterIds,
    bool? isPureConnection,
    bool? showConnectionAnimation,
    List<MysteryOrb>? mysteryOrbs,
    int? consecutivePenalties,
    bool? scoreMultiplierActive,
    MysteryOutcome? lastMysteryOutcome,
    bool clearLastMysteryOutcome = false,
    int? pendingMysteryOrbId,
    bool clearPendingMysteryOrb = false,
    DateTime? mysteryOrbDwellStartTime,
    bool clearMysteryOrbDwellStartTime = false,
    int? pendingLetterId,
    bool clearPendingLetterId = false,
    DateTime? letterDwellStartTime,
    bool clearLetterDwellStartTime = false,
    int? lastConnectedLetterId,
    bool clearLastConnectedLetterId = false,
    bool? skipCheatUsedThisRound,
    int? stars,
    int? starsEarnedThisGame,
    int? lastStarThreshold,
    bool? showStarEarnedAnimation,
  }) {
    return GameState(
      letters: letters ?? this.letters,
      selectedLetterIds: selectedLetterIds ?? this.selectedLetterIds,
      committedWord: committedWord ?? this.committedWord,
      completedWords: completedWords ?? this.completedWords,
      score: score ?? this.score,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isPlaying: isPlaying ?? this.isPlaying,
      isDragging: isDragging ?? this.isDragging,
      currentDragPosition: clearDragPosition ? null : (currentDragPosition ?? this.currentDragPosition),
      phase: phase ?? this.phase,
      currentLetter: clearCurrentLetter ? null : (currentLetter ?? this.currentLetter),
      completedLetters: completedLetters ?? this.completedLetters,
      letterRound: letterRound ?? this.letterRound,
      isWinner: isWinner ?? this.isWinner,
      lastAnswerCorrect: clearLastAnswerCorrect ? null : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      currentCategories: currentCategories ?? this.currentCategories,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      spaceUsageCount: spaceUsageCount ?? this.spaceUsageCount,
      repeatUsageCount: repeatUsageCount ?? this.repeatUsageCount,
      letterRoundStartScore: letterRoundStartScore ?? this.letterRoundStartScore,
      lastTimeBonus: clearLastTimeBonus ? null : (lastTimeBonus ?? this.lastTimeBonus),
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      hintWord: clearHintWord ? null : (hintWord ?? this.hintWord),
      hintLetterIds: clearHintWord ? const [] : (hintLetterIds ?? this.hintLetterIds),
      hintAnimationIndex: clearHintWord ? 0 : (hintAnimationIndex ?? this.hintAnimationIndex),
      usedHintWords: clearUsedHintWords ? const {} : (usedHintWords ?? this.usedHintWords),
      approachingLetterIds: approachingLetterIds ?? this.approachingLetterIds,
      isPureConnection: isPureConnection ?? this.isPureConnection,
      showConnectionAnimation: showConnectionAnimation ?? this.showConnectionAnimation,
      mysteryOrbs: mysteryOrbs ?? this.mysteryOrbs,
      consecutivePenalties: consecutivePenalties ?? this.consecutivePenalties,
      scoreMultiplierActive: scoreMultiplierActive ?? this.scoreMultiplierActive,
      lastMysteryOutcome: clearLastMysteryOutcome ? null : (lastMysteryOutcome ?? this.lastMysteryOutcome),
      pendingMysteryOrbId: clearPendingMysteryOrb ? null : (pendingMysteryOrbId ?? this.pendingMysteryOrbId),
      mysteryOrbDwellStartTime: clearMysteryOrbDwellStartTime ? null : (mysteryOrbDwellStartTime ?? this.mysteryOrbDwellStartTime),
      pendingLetterId: clearPendingLetterId ? null : (pendingLetterId ?? this.pendingLetterId),
      letterDwellStartTime: clearLetterDwellStartTime ? null : (letterDwellStartTime ?? this.letterDwellStartTime),
      lastConnectedLetterId: clearLastConnectedLetterId ? null : (lastConnectedLetterId ?? this.lastConnectedLetterId),
      skipCheatUsedThisRound: skipCheatUsedThisRound ?? this.skipCheatUsedThisRound,
      stars: stars ?? this.stars,
      starsEarnedThisGame: starsEarnedThisGame ?? this.starsEarnedThisGame,
      lastStarThreshold: lastStarThreshold ?? this.lastStarThreshold,
      showStarEarnedAnimation: showStarEarnedAnimation ?? this.showStarEarnedAnimation,
    );
  }
}

class GameInitial extends GameState {
  const GameInitial() : super();
}
