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

  /// Points earned in current letter round
  int get pointsEarnedInRound => score - letterRoundStartScore;

  /// Categories completed for current letter
  int get categoriesCompletedForLetter => categoryIndex;

  /// Total bonus count for current word
  int get totalBonusCount => spaceUsageCount + repeatUsageCount;

  /// Total categories to complete per letter
  static const int categoriesPerLetter = 5;

  /// Get the current selection as a string (just the active drag)
  String get currentSelection => selectedLetterIds.map((id) {
        if (id == spaceId) return ' ';
        return letters.firstWhere((l) => l.id == id).letter;
      }).join();

  /// Get the full word being built (committed + current selection)
  String get currentWord => committedWord + currentSelection;

  /// Get selected letter nodes in order (spaces are represented as null)
  List<LetterNode?> get selectedLetters => selectedLetterIds.map((id) {
        if (id == spaceId) return null; // null represents space
        return letters.firstWhere((l) => l.id == id);
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
    );
  }
}

class GameInitial extends GameState {
  const GameInitial() : super();
}
