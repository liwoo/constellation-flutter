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

class GameState extends Equatable {
  const GameState({
    this.letters = const [],
    this.selectedLetterIds = const [],
    this.completedWords = const [],
    this.score = 0,
    this.timeRemaining = 60,
    this.category = 'SPORTS BRANDS',
    this.difficulty = 2,
    this.isPlaying = false,
    this.isDragging = false,
    this.currentDragPosition,
  });

  final List<LetterNode> letters;
  final List<int> selectedLetterIds; // Order matters, same id can appear multiple times
  final List<String> completedWords;
  final int score;
  final int timeRemaining;
  final String category;
  final int difficulty;
  final bool isPlaying;
  final bool isDragging;
  final Offset? currentDragPosition; // Relative position (0.0-1.0)

  /// Get the current word from selected letters
  String get currentWord => selectedLetterIds
      .map((id) => letters.firstWhere((l) => l.id == id))
      .map((node) => node.letter)
      .join();

  /// Get selected letter nodes in order
  List<LetterNode> get selectedLetters => selectedLetterIds
      .map((id) => letters.firstWhere((l) => l.id == id))
      .toList();

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
    );
  }
}

class GameInitial extends GameState {
  const GameInitial() : super();
}
