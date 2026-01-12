part of 'practice_cubit.dart';

/// Practice word with difficulty
class PracticeWord {
  final String word;
  final int difficulty;

  const PracticeWord({required this.word, required this.difficulty});

  factory PracticeWord.fromJson(Map<String, dynamic> json) {
    return PracticeWord(
      word: json['word'] as String,
      difficulty: json['difficulty'] as int,
    );
  }

  /// Get individual words (for multi-word phrases)
  List<String> get words => word.split(' ');

  /// Check if this is a multi-word phrase
  bool get isMultiWord => word.contains(' ');
}

/// Practice phase
enum PracticePhase {
  /// Initial state - show start screen
  notStarted,
  /// Playing a round
  playing,
  /// Session complete
  completed,
}

/// {@template practice}
/// PracticeState for practice mode
/// {@endtemplate}
class PracticeState extends Equatable {
  /// {@macro practice}
  const PracticeState({
    this.letters = const [],
    this.selectedLetterIds = const [],
    this.committedWord = '',
    this.phase = PracticePhase.notStarted,
    this.currentWordIndex = 0,
    this.sessionWords = const [],
    this.completedCount = 0,
    this.isDragging = false,
    this.currentDragPosition,
    this.showSuccess = false,
  });

  /// Special ID for space character in selectedLetterIds
  static const int spaceId = -1;

  /// Total words per practice session
  static const int wordsPerSession = 10;

  final List<LetterNode> letters;
  final List<int> selectedLetterIds;
  final String committedWord;
  final PracticePhase phase;
  final int currentWordIndex;
  final List<PracticeWord> sessionWords;
  final int completedCount;
  final bool isDragging;
  final Offset? currentDragPosition;
  final bool showSuccess;

  /// Get current target word
  PracticeWord? get currentWord =>
      sessionWords.isNotEmpty && currentWordIndex < sessionWords.length
          ? sessionWords[currentWordIndex]
          : null;

  /// Get the current selection as a string
  String get currentSelection => selectedLetterIds.map((id) {
        if (id == spaceId) return ' ';
        return letters.firstWhere((l) => l.id == id).letter;
      }).join();

  /// Get the full word being built (committed + current selection)
  String get builtWord => committedWord + currentSelection;

  /// Get selected letter nodes in order (spaces are represented as null)
  List<LetterNode?> get selectedLetters => selectedLetterIds.map((id) {
        if (id == spaceId) return null;
        return letters.firstWhere((l) => l.id == id);
      }).toList();

  /// Check if there's any word content
  bool get hasWordContent =>
      committedWord.isNotEmpty || selectedLetterIds.isNotEmpty;

  /// Progress through session (0.0 to 1.0)
  double get progress => completedCount / wordsPerSession;

  /// Check if current input matches target
  bool get isMatch =>
      currentWord != null &&
      builtWord.toUpperCase().trim() == currentWord!.word.toUpperCase();

  @override
  List<Object?> get props => [
        letters,
        selectedLetterIds,
        committedWord,
        phase,
        currentWordIndex,
        sessionWords,
        completedCount,
        isDragging,
        currentDragPosition,
        showSuccess,
      ];

  PracticeState copyWith({
    List<LetterNode>? letters,
    List<int>? selectedLetterIds,
    String? committedWord,
    PracticePhase? phase,
    int? currentWordIndex,
    List<PracticeWord>? sessionWords,
    int? completedCount,
    bool? isDragging,
    Offset? currentDragPosition,
    bool clearDragPosition = false,
    bool? showSuccess,
  }) {
    return PracticeState(
      letters: letters ?? this.letters,
      selectedLetterIds: selectedLetterIds ?? this.selectedLetterIds,
      committedWord: committedWord ?? this.committedWord,
      phase: phase ?? this.phase,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      sessionWords: sessionWords ?? this.sessionWords,
      completedCount: completedCount ?? this.completedCount,
      isDragging: isDragging ?? this.isDragging,
      currentDragPosition:
          clearDragPosition ? null : (currentDragPosition ?? this.currentDragPosition),
      showSuccess: showSuccess ?? this.showSuccess,
    );
  }
}

/// {@template practice_initial}
/// The initial state of PracticeState
/// {@endtemplate}
class PracticeInitial extends PracticeState {
  /// {@macro practice_initial}
  const PracticeInitial() : super();
}
