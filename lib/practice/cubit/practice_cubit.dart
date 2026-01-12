import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/shared/services/services.dart';

part 'practice_state.dart';

class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit() : super(const PracticeInitial()) {
    _loadWords();
    _initializeLetters();
  }

  final _random = Random();
  List<PracticeWord> _allWords = [];

  // Sticky/magnetic selection tracking (same as GameCubit)
  int? _pendingLetterId;
  DateTime? _pendingLetterEnteredAt;
  Offset? _lastDragPosition;
  DateTime? _lastDragTime;

  // Tuning constants
  static const Duration _dwellTime = Duration(seconds: 2);
  static const double _passThroughVelocity = 0.15;
  static const double _innerHitRadius = 0.035;
  static const double _outerHitRadius = 0.055;

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

  void _initializeLetters() {
    final letters = _generateLetterNodes();
    emit(state.copyWith(letters: letters));
  }

  /// Start a new practice session
  void startSession() {
    _initializeLetters();

    // Select 10 random words, progressively harder
    final sessionWords = _selectSessionWords();

    emit(state.copyWith(
      phase: PracticePhase.playing,
      sessionWords: sessionWords,
      currentWordIndex: 0,
      completedCount: 0,
      selectedLetterIds: [],
      committedWord: '',
      showSuccess: false,
    ));
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

  /// Generate letter nodes for constellation
  List<LetterNode> _generateLetterNodes() {
    final random = Random();
    final letters = <LetterNode>[];

    const cols = 6;
    const rows = 5;
    const paddingX = 0.10;
    const paddingY = 0.05;
    const availableWidth = 1.0 - (paddingX * 2);
    const availableHeight = 0.88 - paddingY;
    const cellWidth = availableWidth / cols;
    const cellHeight = availableHeight / rows;
    const jitterX = cellWidth * 0.25;
    const jitterY = cellHeight * 0.20;

    final gridPositions = <Offset>[];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final baseX = paddingX + (col + 0.5) * cellWidth;
        final baseY = paddingY + (row + 0.5) * cellHeight;
        final x = baseX + (random.nextDouble() - 0.5) * 2 * jitterX;
        final y = baseY + (random.nextDouble() - 0.5) * 2 * jitterY;
        gridPositions.add(Offset(
          x.clamp(paddingX, 1.0 - paddingX),
          y.clamp(paddingY, 0.88),
        ));
      }
    }

    gridPositions.shuffle(random);

    for (int i = 0; i < 26; i++) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
      final points = _letterPoints[letter] ?? 1;
      letters.add(LetterNode(
        id: i,
        letter: letter,
        points: points,
        position: gridPositions[i],
      ));
    }

    return letters;
  }

  /// Start dragging from a position
  void startDrag(Offset relativePosition) {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    _lastDragPosition = relativePosition;
    _lastDragTime = DateTime.now();

    final hasExistingSelection = state.selectedLetterIds.isNotEmpty;
    final hitNode = _findNodeAtPosition(relativePosition, _innerHitRadius);

    if (hasExistingSelection) {
      if (hitNode != null) {
        final lastId = state.selectedLetterIds.last;
        if (hitNode.id != lastId) {
          final newSelection = [...state.selectedLetterIds, hitNode.id];
          emit(state.copyWith(
            isDragging: true,
            selectedLetterIds: newSelection,
            currentDragPosition: relativePosition,
          ));
          _checkWordMatch();
        } else {
          emit(state.copyWith(
            isDragging: true,
            currentDragPosition: relativePosition,
          ));
        }
      } else {
        emit(state.copyWith(
          isDragging: true,
          currentDragPosition: relativePosition,
        ));
      }
    } else {
      if (hitNode != null) {
        emit(state.copyWith(
          isDragging: true,
          selectedLetterIds: [hitNode.id],
          currentDragPosition: relativePosition,
        ));
      } else {
        emit(state.copyWith(
          isDragging: true,
          currentDragPosition: relativePosition,
        ));
      }
    }
  }

  double _calculateVelocity(Offset currentPosition) {
    if (_lastDragPosition == null || _lastDragTime == null) return 0.0;

    final now = DateTime.now();
    final timeDelta = now.difference(_lastDragTime!).inMicroseconds / 1000000.0;
    if (timeDelta <= 0) return 0.0;

    final dx = currentPosition.dx - _lastDragPosition!.dx;
    final dy = currentPosition.dy - _lastDragPosition!.dy;
    final distance = (dx * dx + dy * dy);
    return distance > 0 ? (distance / timeDelta) : 0.0;
  }

  /// Update drag position
  void updateDrag(Offset relativePosition) {
    if (!state.isDragging) return;

    final now = DateTime.now();
    final velocity = _calculateVelocity(relativePosition);
    final isPassingThrough = velocity > _passThroughVelocity;

    _lastDragPosition = relativePosition;
    _lastDragTime = now;

    final innerHitNode = _findNodeAtPosition(relativePosition, _innerHitRadius);
    final outerHitNode = _findNodeAtPosition(relativePosition, _outerHitRadius);

    final lastSelectedId = state.selectedLetterIds.isNotEmpty
        ? state.selectedLetterIds.last
        : null;

    if (innerHitNode != null && innerHitNode.id != lastSelectedId) {
      if (!isPassingThrough) {
        _confirmLetterSelection(innerHitNode.id, relativePosition);
        return;
      }
    }

    if (outerHitNode != null && outerHitNode.id != lastSelectedId) {
      if (isPassingThrough) {
        if (_pendingLetterId == outerHitNode.id) {
          _pendingLetterId = null;
          _pendingLetterEnteredAt = null;
        }
        emit(state.copyWith(currentDragPosition: relativePosition));
        return;
      }

      if (_pendingLetterId == outerHitNode.id) {
        final elapsed = now.difference(_pendingLetterEnteredAt!);
        if (elapsed >= _dwellTime) {
          _confirmLetterSelection(outerHitNode.id, relativePosition);
        } else {
          emit(state.copyWith(currentDragPosition: relativePosition));
        }
      } else {
        _pendingLetterId = outerHitNode.id;
        _pendingLetterEnteredAt = now;
        emit(state.copyWith(currentDragPosition: relativePosition));
      }
      return;
    }

    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    emit(state.copyWith(currentDragPosition: relativePosition));
  }

  void _confirmLetterSelection(int letterId, Offset position) {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;

    AudioService.instance.play(GameSound.letterSelect);
    HapticService.instance.medium();

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
    _lastDragPosition = null;
    _lastDragTime = null;
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
      ));
    } else {
      // Next word
      _initializeLetters();
      emit(state.copyWith(
        currentWordIndex: newIndex,
        completedCount: newCompletedCount,
        selectedLetterIds: [],
        committedWord: '',
        showSuccess: false,
      ));
    }
  }

  /// Reset to start screen
  void resetSession() {
    _initializeLetters();
    emit(const PracticeState());
  }

  /// Skip current word (for practice)
  void skipWord() {
    _advanceToNextWord();
  }
}
