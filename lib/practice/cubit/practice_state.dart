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

  /// Check if this word has double letters (e.g., MISSISSIPPI has SS, PP)
  bool get hasDoubleLetters {
    final upperWord = word.toUpperCase().replaceAll(' ', '');
    for (int i = 0; i < upperWord.length - 1; i++) {
      if (upperWord[i] == upperWord[i + 1]) {
        return true;
      }
    }
    return false;
  }

  /// Check if this word has tricky navigation paths on QWERTY layout
  /// Returns true if consecutive letters have other letters between them
  bool get hasTrickyNavigation {
    // QWERTY keyboard layout - positions for detecting adjacency
    const qwertyRows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];

    // Build position map
    final positions = <String, (int row, int col)>{};
    for (int row = 0; row < qwertyRows.length; row++) {
      for (int col = 0; col < qwertyRows[row].length; col++) {
        positions[qwertyRows[row][col]] = (row, col);
      }
    }

    final upperWord = word.toUpperCase().replaceAll(' ', '');
    if (upperWord.length < 2) return false;

    // Check if consecutive letters require crossing over other letters
    for (int i = 0; i < upperWord.length - 1; i++) {
      final from = upperWord[i];
      final to = upperWord[i + 1];

      final fromPos = positions[from];
      final toPos = positions[to];
      if (fromPos == null || toPos == null) continue;

      // If letters span more than 2 columns on same row, or cross rows diagonally
      // with significant horizontal distance, there might be interference
      final rowDiff = (fromPos.$1 - toPos.$1).abs();
      final colDiff = (fromPos.$2 - toPos.$2).abs();

      // Tricky if: same row but far apart (3+ cols) OR crossing rows with 2+ col distance
      if (rowDiff == 0 && colDiff >= 3) return true;
      if (rowDiff >= 1 && colDiff >= 2) return true;
    }

    return false;
  }
}

/// Tutorial types for practice mode
enum TutorialType {
  /// How the drag connection indicators work (shown first)
  dragIndicators,
  /// How to spell words with spaces (multi-word)
  spacedWords,
  /// How to spell words with double letters
  doubleLetters,
  /// How to navigate around interfering letters
  navigation,
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
    this.showTutorial,
    this.hasSeenDragIndicatorsTutorial = false,
    this.hasSeenDoubleLettersTutorial = false,
    this.hasSeenSpacedWordsTutorial = false,
    this.hasSeenNavigationTutorial = false,
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
  final TutorialType? showTutorial; // Tutorial to show, null if none
  final bool hasSeenDragIndicatorsTutorial;
  final bool hasSeenDoubleLettersTutorial;
  final bool hasSeenSpacedWordsTutorial;
  final bool hasSeenNavigationTutorial;

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
        showTutorial,
        hasSeenDragIndicatorsTutorial,
        hasSeenDoubleLettersTutorial,
        hasSeenSpacedWordsTutorial,
        hasSeenNavigationTutorial,
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
    TutorialType? showTutorial,
    bool clearTutorial = false,
    bool? hasSeenDragIndicatorsTutorial,
    bool? hasSeenDoubleLettersTutorial,
    bool? hasSeenSpacedWordsTutorial,
    bool? hasSeenNavigationTutorial,
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
      showTutorial: clearTutorial ? null : (showTutorial ?? this.showTutorial),
      hasSeenDragIndicatorsTutorial:
          hasSeenDragIndicatorsTutorial ?? this.hasSeenDragIndicatorsTutorial,
      hasSeenDoubleLettersTutorial:
          hasSeenDoubleLettersTutorial ?? this.hasSeenDoubleLettersTutorial,
      hasSeenSpacedWordsTutorial:
          hasSeenSpacedWordsTutorial ?? this.hasSeenSpacedWordsTutorial,
      hasSeenNavigationTutorial:
          hasSeenNavigationTutorial ?? this.hasSeenNavigationTutorial,
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
