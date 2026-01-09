part of 'alpha_quest_cubit.dart';

/// State for Alpha Quest game mode
class AlphaQuestState extends Equatable {
  const AlphaQuestState({
    this.timeRemaining = 120,
    this.score = 0,
    this.currentRound = 1,
    this.completedLetters = const [],
    this.isPlaying = false,
    this.isGameOver = false,
    this.isWinner = false,
    this.currentLetter,
    this.currentCategory,
    this.lastAnswerCorrect,
  });

  /// Time remaining in seconds
  final int timeRemaining;

  /// Current score
  final int score;

  /// Current round number
  final int currentRound;

  /// Letters that have been completed
  final List<String> completedLetters;

  /// Whether the game is currently active
  final bool isPlaying;

  /// Whether the game has ended
  final bool isGameOver;

  /// Whether the player won (completed all 26 letters)
  final bool isWinner;

  /// Current letter to find a word for
  final String? currentLetter;

  /// Current category for the word
  final String? currentCategory;

  /// Result of the last answer (null = no answer yet)
  final bool? lastAnswerCorrect;

  /// Get remaining letters count
  int get remainingLettersCount => 26 - completedLetters.length;

  /// Get progress percentage (0.0 to 1.0)
  double get progress => completedLetters.length / 26.0;

  AlphaQuestState copyWith({
    int? timeRemaining,
    int? score,
    int? currentRound,
    List<String>? completedLetters,
    bool? isPlaying,
    bool? isGameOver,
    bool? isWinner,
    String? currentLetter,
    String? currentCategory,
    bool? lastAnswerCorrect,
  }) {
    return AlphaQuestState(
      timeRemaining: timeRemaining ?? this.timeRemaining,
      score: score ?? this.score,
      currentRound: currentRound ?? this.currentRound,
      completedLetters: completedLetters ?? this.completedLetters,
      isPlaying: isPlaying ?? this.isPlaying,
      isGameOver: isGameOver ?? this.isGameOver,
      isWinner: isWinner ?? this.isWinner,
      currentLetter: currentLetter ?? this.currentLetter,
      currentCategory: currentCategory ?? this.currentCategory,
      lastAnswerCorrect: lastAnswerCorrect ?? this.lastAnswerCorrect,
    );
  }

  @override
  List<Object?> get props => [
        timeRemaining,
        score,
        currentRound,
        completedLetters,
        isPlaying,
        isGameOver,
        isWinner,
        currentLetter,
        currentCategory,
        lastAnswerCorrect,
      ];
}
