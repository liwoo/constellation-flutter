import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/shared/constants/game_constants.dart';
import 'package:constellation_app/shared/services/services.dart';

part 'practice_state.dart';

class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit() : super(const PracticeInitial()) {
    _loadWords();
  }

  final _random = Random();
  List<PracticeWord> _allWords = [];

  // Sticky/magnetic selection tracking (same as GameCubit)
  int? _pendingLetterId;
  DateTime? _pendingLetterEnteredAt;

  // Tuning constants - use shared config
  static const Duration _dwellTime = Duration(milliseconds: HitDetectionConfig.dwellTimeMs);
  static const double _outerHitRadius = HitDetectionConfig.outerHitRadius;

  // Letter point values
  static const Map<String, int> _letterPoints = {
    'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4, 'G': 2, 'H': 4,
    'I': 1, 'J': 8, 'K': 5, 'L': 1, 'M': 3, 'N': 1, 'O': 1, 'P': 3,
    'Q': 10, 'R': 1, 'S': 1, 'T': 1, 'U': 1, 'V': 4, 'W': 4, 'X': 8,
    'Y': 4, 'Z': 10,
  };

  Future<void> _loadWords() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/practice_words.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final wordsList = data['words'] as List;
      _allWords = wordsList.map((w) => PracticeWord.fromJson(w as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback words if loading fails
      _allWords = [
        const PracticeWord(word: 'CAT', difficulty: 1),
        const PracticeWord(word: 'DOG', difficulty: 1),
        const PracticeWord(word: 'STAR', difficulty: 2),
        const PracticeWord(word: 'MOON', difficulty: 2),
        const PracticeWord(word: 'TIGER', difficulty: 3),
        const PracticeWord(word: 'HOUSE', difficulty: 3),
        const PracticeWord(word: 'PLANET', difficulty: 4),
        const PracticeWord(word: 'RAINBOW', difficulty: 5),
        const PracticeWord(word: 'ELEPHANT', difficulty: 6),
        const PracticeWord(word: 'ICE CREAM', difficulty: 8),
      ];
    }
  }

  /// Start a new practice session
  void startSession() {
    // Select 10 random words, progressively harder
    final sessionWords = _selectSessionWords();

    // Check if first word needs a tutorial
    TutorialType? tutorial;
    if (sessionWords.isNotEmpty) {
      final firstWord = sessionWords[0];
      if (firstWord.isMultiWord && !state.hasSeenSpacedWordsTutorial) {
        tutorial = TutorialType.spacedWords;
      } else if (firstWord.hasDoubleLetters && !state.hasSeenDoubleLettersTutorial) {
        tutorial = TutorialType.doubleLetters;
      } else if (firstWord.hasTrickyNavigation && !state.hasSeenNavigationTutorial) {
        tutorial = TutorialType.navigation;
      }
    }

    // Generate letters for the first word
    final letters = sessionWords.isNotEmpty
        ? _generateLettersForWord(sessionWords[0].word)
        : <LetterNode>[];

    emit(state.copyWith(
      phase: PracticePhase.playing,
      sessionWords: sessionWords,
      currentWordIndex: 0,
      completedCount: 0,
      selectedLetterIds: [],
      committedWord: '',
      showSuccess: false,
      showTutorial: tutorial,
      clearTutorial: tutorial == null,
      letters: letters,
    ));
  }

  /// Dismiss the tutorial modal
  void dismissTutorial() {
    // Mark the tutorial type as seen
    if (state.showTutorial == TutorialType.spacedWords) {
      emit(state.copyWith(
        clearTutorial: true,
        hasSeenSpacedWordsTutorial: true,
      ));
    } else if (state.showTutorial == TutorialType.doubleLetters) {
      emit(state.copyWith(
        clearTutorial: true,
        hasSeenDoubleLettersTutorial: true,
      ));
    } else if (state.showTutorial == TutorialType.navigation) {
      emit(state.copyWith(
        clearTutorial: true,
        hasSeenNavigationTutorial: true,
      ));
    } else {
      emit(state.copyWith(clearTutorial: true));
    }
  }

  /// Select 10 words for the session, progressively harder
  List<PracticeWord> _selectSessionWords() {
    final selected = <PracticeWord>[];

    // Select words progressively: 2 easy, 2 medium-easy, 2 medium, 2 medium-hard, 2 hard
    final difficultyRanges = [
      [1, 2],    // Words 1-2: difficulty 1-2
      [2, 3],    // Words 3-4: difficulty 2-3
      [3, 5],    // Words 5-6: difficulty 3-5
      [5, 7],    // Words 7-8: difficulty 5-7
      [7, 10],   // Words 9-10: difficulty 7-10
    ];

    for (final range in difficultyRanges) {
      final candidates = _allWords
          .where((w) => w.difficulty >= range[0] && w.difficulty <= range[1])
          .where((w) => !selected.contains(w))
          .toList();
      candidates.shuffle(_random);
      selected.addAll(candidates.take(2));
    }

    // If we don't have enough, fill with random words
    while (selected.length < PracticeState.wordsPerSession && _allWords.isNotEmpty) {
      final remaining = _allWords.where((w) => !selected.contains(w)).toList();
      if (remaining.isEmpty) break;
      remaining.shuffle(_random);
      selected.add(remaining.first);
    }

    return selected;
  }

  /// Generate letter nodes for a specific target word
  /// Shows only letters needed for the word plus some random extras (5-15 total)
  /// Positions are randomized in a grid layout like Alpha Quest mode
  List<LetterNode> _generateLettersForWord(String targetWord) {
    // Extract unique letters needed for the target word
    final neededLetters = <String>{};
    for (final char in targetWord.toUpperCase().split('')) {
      if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
        neededLetters.add(char);
      }
    }

    // Determine target count: word letters + 2-8 random extras (5-15 total)
    final wordLetterCount = neededLetters.length;
    final minExtra = max(0, 5 - wordLetterCount);
    final maxExtra = max(minExtra, 15 - wordLetterCount);
    final extraCount = minExtra + _random.nextInt(maxExtra - minExtra + 1);

    // Get random extra letters (not in the word)
    final allLetters = List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i));
    final availableExtras = allLetters.where((l) => !neededLetters.contains(l)).toList();
    availableExtras.shuffle(_random);
    final extraLetters = availableExtras.take(extraCount).toSet();

    // Combine and sort for consistent IDs
    final allNeededLetters = [...neededLetters, ...extraLetters].toList();
    allNeededLetters.sort();

    // Generate randomized grid positions
    final positions = _generateRandomizedPositions(allNeededLetters.length);

    // Shuffle position assignment for randomness
    final shuffledPositions = List<Offset>.from(positions);
    shuffledPositions.shuffle(_random);

    // Create letter nodes
    final letters = <LetterNode>[];
    for (int i = 0; i < allNeededLetters.length; i++) {
      final letter = allNeededLetters[i];
      final points = _letterPoints[letter] ?? 1;
      final id = letter.codeUnitAt(0) - 'A'.codeUnitAt(0);

      letters.add(LetterNode(
        id: id,
        letter: letter,
        points: points,
        position: shuffledPositions[i],
      ));
    }

    return letters;
  }

  /// Generate randomized grid positions for the given number of items
  List<Offset> _generateRandomizedPositions(int count) {
    if (count == 0) return [];

    // Layout bounds (same as Alpha Quest)
    const paddingX = LayoutConfig.gridPaddingX;
    const paddingY = LayoutConfig.gridPaddingY;
    const maxY = LayoutConfig.gridAvailableHeight;

    // Calculate grid dimensions
    final cols = count <= 9 ? 3 : (count <= 16 ? 4 : 5);
    final rows = (count / cols).ceil();
    final availableWidth = 1.0 - (paddingX * 2);
    final availableHeight = maxY - paddingY;
    final cellWidth = availableWidth / cols;
    final cellHeight = availableHeight / rows;
    final jitterX = cellWidth * LayoutConfig.positionJitter;
    final jitterY = cellHeight * LayoutConfig.positionJitter;

    final positions = <Offset>[];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (positions.length >= count) break;
        final baseX = paddingX + (col + 0.5) * cellWidth;
        final baseY = paddingY + (row + 0.5) * cellHeight;
        final x = baseX + (_random.nextDouble() - 0.5) * 2 * jitterX;
        final y = baseY + (_random.nextDouble() - 0.5) * 2 * jitterY;
        positions.add(Offset(
          x.clamp(paddingX, 1.0 - paddingX),
          y.clamp(paddingY, maxY),
        ));
      }
    }

    return positions;
  }

  /// Start dragging from a position
  /// Does NOT immediately select - all selections require dwell time
  void startDrag(Offset relativePosition) {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;

    final hitNode = _findNodeAtPosition(relativePosition, _outerHitRadius);

    if (hitNode != null) {
      final lastSelectedId = state.selectedLetterIds.isNotEmpty
          ? state.selectedLetterIds.last
          : null;

      if (hitNode.id != lastSelectedId) {
        // Start dwell timer for this letter
        _pendingLetterId = hitNode.id;
        _pendingLetterEnteredAt = DateTime.now();
      }
      // If same letter, just continue dragging (no double letters via tap)
    }

    emit(state.copyWith(
      isDragging: true,
      currentDragPosition: relativePosition,
    ));
  }

  /// Update drag position
  /// All selections require dwell time - no immediate selection regardless of velocity
  void updateDrag(Offset relativePosition) {
    if (!state.isDragging) return;

    final now = DateTime.now();
    final hitNode = _findNodeAtPosition(relativePosition, _outerHitRadius);

    final lastSelectedId = state.selectedLetterIds.isNotEmpty
        ? state.selectedLetterIds.last
        : null;

    // Check if we're over a letter (and it's not the last selected one)
    if (hitNode != null && hitNode.id != lastSelectedId) {
      if (_pendingLetterId == hitNode.id) {
        // Check if dwell time has elapsed
        final elapsed = now.difference(_pendingLetterEnteredAt!);
        if (elapsed >= _dwellTime) {
          _confirmLetterSelection(hitNode.id, relativePosition, fromDrag: true);
        } else {
          // Still dwelling - just update position
          emit(state.copyWith(currentDragPosition: relativePosition));
        }
      } else {
        // New letter - start dwell timer
        _pendingLetterId = hitNode.id;
        _pendingLetterEnteredAt = now;
        emit(state.copyWith(currentDragPosition: relativePosition));
      }
      return;
    }

    // Outside all hit zones - reset pending state
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    emit(state.copyWith(currentDragPosition: relativePosition));
  }

  void _confirmLetterSelection(int letterId, Offset position, {bool fromDrag = false}) {
    // Prevent consecutive duplicates during drag
    // Double letters are only allowed via the x2 repeat button
    if (fromDrag && state.selectedLetterIds.isNotEmpty && state.selectedLetterIds.last == letterId) {
      return; // Skip - this letter is already the last selected
    }

    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;

    AudioService.instance.play(GameSound.letterSelect);
    HapticService.instance.light(); // Light haptic, same as game cubit

    final newSelection = [...state.selectedLetterIds, letterId];
    emit(state.copyWith(
      selectedLetterIds: newSelection,
      currentDragPosition: position,
    ));

    // Check if word is complete after selection
    _checkWordMatch();
  }

  /// End dragging
  void endDrag() {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    emit(state.copyWith(
      isDragging: false,
      clearDragPosition: true,
    ));
  }

  LetterNode? _findNodeAtPosition(Offset position, double radius) {
    for (final node in state.letters) {
      final dx = (node.position.dx - position.dx).abs();
      final dy = (node.position.dy - position.dy).abs();
      final distanceSquared = (dx * dx + dy * dy);
      if (distanceSquared < radius * radius) {
        return node;
      }
    }
    return null;
  }

  /// Clear current selection
  void clearSelection() {
    emit(state.copyWith(
      selectedLetterIds: [],
      committedWord: '',
      clearDragPosition: true,
    ));
  }

  /// Insert a space (commit current selection)
  void insertSpace() {
    if (state.selectedLetterIds.isEmpty) return;

    final newCommitted = '${state.committedWord}${state.currentSelection} ';
    emit(state.copyWith(
      committedWord: newCommitted,
      selectedLetterIds: [],
    ));

    _checkWordMatch();
  }

  /// Repeat last letter
  void repeatLastLetter() {
    if (state.selectedLetterIds.isEmpty) return;
    final lastId = state.selectedLetterIds.last;
    if (lastId == PracticeState.spaceId) return;

    final newSelection = [...state.selectedLetterIds, lastId];
    emit(state.copyWith(selectedLetterIds: newSelection));

    _checkWordMatch();
  }

  /// Check if the built word matches target
  void _checkWordMatch() {
    if (state.currentWord == null) return;

    final target = state.currentWord!.word.toUpperCase().trim();
    final built = state.builtWord.toUpperCase().trim();

    if (built == target) {
      // Success!
      AudioService.instance.play(GameSound.wordCorrect);
      HapticService.instance.success();

      emit(state.copyWith(showSuccess: true));

      // Move to next word after a delay
      Future.delayed(const Duration(milliseconds: 800), () {
        _advanceToNextWord();
      });
    }
  }

  void _advanceToNextWord() {
    final newCompletedCount = state.completedCount + 1;
    final newIndex = state.currentWordIndex + 1;

    if (newCompletedCount >= PracticeState.wordsPerSession) {
      // Session complete!
      emit(state.copyWith(
        phase: PracticePhase.completed,
        completedCount: newCompletedCount,
        showSuccess: false,
        clearTutorial: true,
      ));
    } else {
      // Next word - generate letters specific to this word
      final nextWord = state.sessionWords[newIndex];
      final letters = _generateLettersForWord(nextWord.word);

      // Check if next word needs a tutorial
      TutorialType? tutorial;

      if (nextWord.isMultiWord && !state.hasSeenSpacedWordsTutorial) {
        tutorial = TutorialType.spacedWords;
      } else if (nextWord.hasDoubleLetters && !state.hasSeenDoubleLettersTutorial) {
        tutorial = TutorialType.doubleLetters;
      } else if (nextWord.hasTrickyNavigation && !state.hasSeenNavigationTutorial) {
        tutorial = TutorialType.navigation;
      }

      emit(state.copyWith(
        currentWordIndex: newIndex,
        completedCount: newCompletedCount,
        selectedLetterIds: [],
        committedWord: '',
        showSuccess: false,
        showTutorial: tutorial,
        clearTutorial: tutorial == null,
        letters: letters,
      ));
    }
  }

  /// Reset to start screen
  void resetSession() {
    emit(const PracticeState());
  }

  /// Skip current word (for practice)
  void skipWord() {
    _advanceToNextWord();
  }
}
