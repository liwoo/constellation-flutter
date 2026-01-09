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
  /// Game over - win or lose
  gameOver,
}

class GameState extends Equatable {
  const GameState({
    this.letters = const [],
    this.selectedLetterIds = const [],
    this.completedWords = const [],
    this.score = 0,
    this.timeRemaining = 120,
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
  });

  final List<LetterNode> letters;
  final List<int> selectedLetterIds; // Order matters, same id can appear multiple times
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

  /// Categories completed for current letter
  int get categoriesCompletedForLetter => categoryIndex;

  /// Total categories to complete per letter
  static const int categoriesPerLetter = 5;

  /// Get the current word from selected letters
  String get currentWord => selectedLetterIds
      .map((id) => letters.firstWhere((l) => l.id == id))
      .map((node) => node.letter)
      .join();

  /// Get selected letter nodes in order
  List<LetterNode> get selectedLetters => selectedLetterIds
      .map((id) => letters.firstWhere((l) => l.id == id))
      .toList();

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
      ];

  GameState copyWith({
    List<LetterNode>? letters,
    List<int>? selectedLetterIds,
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
  }) {
    return GameState(
      letters: letters ?? this.letters,
      selectedLetterIds: selectedLetterIds ?? this.selectedLetterIds,
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
    );
  }
}

class GameInitial extends GameState {
  const GameInitial() : super();
}
