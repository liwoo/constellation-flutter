part of 'practice_cubit.dart';

/// One bite-sized lesson: a tiny hand-placed board and a word to spell
/// that needs exactly the mechanic being taught.
class PracticeLesson {
  const PracticeLesson({
    required this.title,
    required this.goal,
    required this.word,
    required this.stars,
  });

  final String title;

  /// What this lesson is about, in one line
  final String goal;

  /// Word to spell (may contain a space)
  final String word;

  /// Star letter -> relative position (0-1) on the board
  final Map<String, Offset> stars;
}

/// The practice course, in order
const practiceLessons = [
  PracticeLesson(
    title: 'CONNECT',
    goal: 'Touch the first star, then slide your finger to the next one.',
    word: 'HI',
    stars: {
      'H': Offset(0.28, 0.45),
      'I': Offset(0.72, 0.45),
    },
  ),
  PracticeLesson(
    title: 'WAIT FOR THE CLICK',
    goal: 'Rest on each star until its ring fills and it clicks. Lift too early and it won\'t connect.',
    word: 'CAT',
    stars: {
      'C': Offset(0.2, 0.55),
      'A': Offset(0.5, 0.22),
      'T': Offset(0.8, 0.55),
      'O': Offset(0.5, 0.82),
    },
  ),
  PracticeLesson(
    title: 'TWO WORDS',
    goal: 'Spell the first word, tap ␣ for a space, then spell the next.',
    word: 'ICE CREAM',
    stars: {
      'I': Offset(0.2, 0.25),
      'C': Offset(0.5, 0.18),
      'E': Offset(0.8, 0.3),
      'R': Offset(0.25, 0.65),
      'A': Offset(0.55, 0.78),
      'M': Offset(0.82, 0.68),
    },
  ),
  PracticeLesson(
    title: 'DOUBLE LETTERS',
    goal: 'You can\'t drag onto the same star twice. Tap x2 to repeat the last letter.',
    word: 'BALL',
    stars: {
      'B': Offset(0.22, 0.4),
      'A': Offset(0.5, 0.7),
      'L': Offset(0.78, 0.4),
      'T': Offset(0.5, 0.15),
    },
  ),
];

/// The single next thing the player should do
enum PracticeCue {
  /// Touch the next star to begin a word
  touchStar,

  /// Slide to the next star and hold for the click
  slideAndHold,

  /// Tap the space button
  space,

  /// Tap x2 to repeat the last letter
  repeat,

  /// Word is complete - tap GO
  go,

  /// A wrong star got connected - tap DEL
  delete,
}

enum PracticePhase {
  /// Working through a lesson
  playing,

  /// Lesson just solved - brief celebration before the next one
  lessonComplete,

  /// Every lesson done
  finished,
}

class PracticeState extends Equatable {
  const PracticeState({
    this.lessonIndex = 0,
    this.phase = PracticePhase.playing,
    this.letters = const [],
    this.selectedLetterIds = const [],
    this.committedWord = '',
    this.isDragging = false,
    this.currentDragPosition,
    this.approachingLetterIds = const [],
    this.pendingLetterId,
    this.letterDwellStartTime,
    this.lastConnectedLetterId,
    this.guideIds = const [],
    this.guideIndex = 0,
    this.releasedEarly = false,
    this.submittedTooSoon = false,
  });

  final int lessonIndex;
  final PracticePhase phase;
  final List<LetterNode> letters;
  final List<int> selectedLetterIds;
  final String committedWord; // Words already finished with a space
  final bool isDragging;
  final Offset? currentDragPosition;
  final List<int> approachingLetterIds;
  final int? pendingLetterId;
  final DateTime? letterDwellStartTime;
  final int? lastConnectedLetterId;

  /// "Show me" path, revealed star by star
  final List<int> guideIds;
  final int guideIndex;

  /// Finger lifted while a ring was still filling
  final bool releasedEarly;

  /// GO tapped before the word was finished
  final bool submittedTooSoon;

  PracticeLesson get lesson => practiceLessons[lessonIndex];

  String get targetWord => lesson.word;

  /// Letters in the current (unfinished) word
  String get currentSelection => selectedLetterIds
      .map((id) => letters.firstWhere((l) => l.id == id).letter)
      .join();

  /// Everything spelled so far
  String get builtWord => committedWord + currentSelection;

  bool get hasWordContent => builtWord.isNotEmpty;

  bool get isOnTrack => targetWord.startsWith(builtWord);

  bool get isComplete => builtWord == targetWord;

  /// What the player should do next
  PracticeCue get cue {
    if (!isOnTrack) return PracticeCue.delete;
    if (isComplete) return PracticeCue.go;
    final next = targetWord[builtWord.length];
    if (next == ' ') return PracticeCue.space;
    if (currentSelection.isNotEmpty && builtWord.endsWith(next)) {
      return PracticeCue.repeat;
    }
    return currentSelection.isEmpty ? PracticeCue.touchStar : PracticeCue.slideAndHold;
  }

  /// Letter the player should reach next (null when a button is next)
  String? get nextLetter {
    final c = cue;
    if (c != PracticeCue.touchStar && c != PracticeCue.slideAndHold) return null;
    return targetWord[builtWord.length];
  }

  @override
  List<Object?> get props => [
        lessonIndex,
        phase,
        letters,
        selectedLetterIds,
        committedWord,
        isDragging,
        currentDragPosition,
        approachingLetterIds,
        pendingLetterId,
        letterDwellStartTime,
        lastConnectedLetterId,
        guideIds,
        guideIndex,
        releasedEarly,
        submittedTooSoon,
      ];

  PracticeState copyWith({
    int? lessonIndex,
    PracticePhase? phase,
    List<LetterNode>? letters,
    List<int>? selectedLetterIds,
    String? committedWord,
    bool? isDragging,
    Offset? currentDragPosition,
    bool clearDragPosition = false,
    List<int>? approachingLetterIds,
    int? pendingLetterId,
    DateTime? letterDwellStartTime,
    bool clearPending = false,
    int? lastConnectedLetterId,
    bool clearLastConnected = false,
    List<int>? guideIds,
    int? guideIndex,
    bool? releasedEarly,
    bool? submittedTooSoon,
  }) {
    return PracticeState(
      lessonIndex: lessonIndex ?? this.lessonIndex,
      phase: phase ?? this.phase,
      letters: letters ?? this.letters,
      selectedLetterIds: selectedLetterIds ?? this.selectedLetterIds,
      committedWord: committedWord ?? this.committedWord,
      isDragging: isDragging ?? this.isDragging,
      currentDragPosition:
          clearDragPosition ? null : (currentDragPosition ?? this.currentDragPosition),
      approachingLetterIds: approachingLetterIds ?? this.approachingLetterIds,
      pendingLetterId: clearPending ? null : (pendingLetterId ?? this.pendingLetterId),
      letterDwellStartTime:
          clearPending ? null : (letterDwellStartTime ?? this.letterDwellStartTime),
      lastConnectedLetterId:
          clearLastConnected ? null : (lastConnectedLetterId ?? this.lastConnectedLetterId),
      guideIds: guideIds ?? this.guideIds,
      guideIndex: guideIndex ?? this.guideIndex,
      releasedEarly: releasedEarly ?? this.releasedEarly,
      submittedTooSoon: submittedTooSoon ?? this.submittedTooSoon,
    );
  }
}
