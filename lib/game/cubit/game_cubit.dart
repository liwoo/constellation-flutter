import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(const GameInitial()) {
    _initializeLetters();
  }

  Timer? _timer;
  final _dictionary = CategoryDictionary.instance;
  final _random = Random();

  // Sticky/magnetic selection tracking
  int? _pendingLetterId;
  DateTime? _pendingLetterEnteredAt;
  Offset? _lastDragPosition;
  DateTime? _lastDragTime;

  // Tuning constants
  static const Duration _dwellTime = Duration(seconds: 2);
  // Velocity threshold - if moving faster than this, user is "passing through"
  // Lower = must slow down more to trigger selection (more magnetic/sticky)
  // (relative units per second)
  static const double _passThroughVelocity = 0.15;

  // Letter point values (Scrabble-style)
  static const Map<String, int> _letterPoints = {
    'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4, 'G': 2, 'H': 4,
    'I': 1, 'J': 8, 'K': 5, 'L': 1, 'M': 3, 'N': 1, 'O': 1, 'P': 3,
    'Q': 10, 'R': 1, 'S': 1, 'T': 1, 'U': 1, 'V': 4, 'W': 4, 'X': 8,
    'Y': 4, 'Z': 10,
  };

  void _initializeLetters() {
    // Generate all 26 letters (A-Z) with random non-overlapping positions
    final letters = _generateLetterNodes();
    emit(state.copyWith(letters: letters));
  }

  /// Start Alpha Quest game - go to spinning wheel
  void startGame() {
    _initializeLetters();
    emit(state.copyWith(
      timeRemaining: 120, // Will be set when wheel lands
      score: 0,
      letterRound: 1,
      completedLetters: [],
      isPlaying: false, // Timer not started yet
      isWinner: false,
      phase: GamePhase.spinningWheel,
      clearCurrentLetter: true,
      category: '',
      currentCategories: [],
      categoryIndex: 0,
      clearLastAnswerCorrect: true,
    ));
  }

  /// Start the countdown timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timeRemaining > 0) {
        emit(state.copyWith(timeRemaining: state.timeRemaining - 1));
      } else {
        _endGame(isWinner: false);
      }
    });
  }

  /// Called when spinning wheel lands on a letter
  void onWheelLanded(String letter) {
    final upperLetter = letter.toUpperCase();

    // Get 5 random categories that have words for this letter
    final categories = _get5RandomCategoriesForLetter(upperLetter);

    // Calculate time for this round: 120 - 10 * (letterRound - 1)
    // Round 1: 120s, Round 2: 110s, Round 3: 100s, etc. (min 10s)
    final roundTime = (120 - 10 * (state.letterRound - 1)).clamp(10, 120);

    emit(state.copyWith(
      currentLetter: upperLetter,
      currentCategories: categories,
      categoryIndex: 0,
      category: categories.isNotEmpty ? categories[0] : 'ANIMALS',
      phase: GamePhase.categoryReveal,
      timeRemaining: roundTime,
      isPlaying: true,
      clearLastAnswerCorrect: true,
    ));

    // Start timer when wheel lands
    _startTimer();
  }

  /// Called when category jackpot animation completes
  void onCategoryRevealed() {
    emit(state.copyWith(
      phase: GamePhase.playingRound,
      selectedLetterIds: [],
    ));
  }

  /// Get 5 random categories that have words for the letter
  List<String> _get5RandomCategoriesForLetter(String letter) {
    final validCategories = CategoryDictionary.categories.where((cat) {
      return _dictionary.categoryHasWordsForLetter(cat, letter);
    }).toList();

    if (validCategories.isEmpty) return ['ANIMALS', 'FOODS', 'COUNTRIES', 'SPORTS', 'CITIES'];

    // Shuffle and take up to 5
    validCategories.shuffle(_random);
    return validCategories.take(5).toList();
  }

  /// Get a random category that has words for the letter (fallback)
  String? _getRandomCategoryForLetter(String letter) {
    final validCategories = CategoryDictionary.categories.where((cat) {
      return _dictionary.categoryHasWordsForLetter(cat, letter);
    }).toList();

    if (validCategories.isEmpty) return null;
    return validCategories[_random.nextInt(validCategories.length)];
  }

  /// Get remaining letters for the spinning wheel (A-Y, excluding X)
  List<String> getRemainingLetters() {
    final remaining = <String>[];
    for (var i = 0; i < 26; i++) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
      // Skip X - only 25 letters
      if (letter == 'X') continue;
      if (!state.completedLetters.contains(letter)) {
        remaining.add(letter);
      }
    }
    return remaining;
  }

  /// Generate all 26 letters using grid-based placement with jitter
  /// This ensures no overlaps while still looking organic
  List<LetterNode> _generateLetterNodes() {
    final random = Random();
    final letters = <LetterNode>[];

    // Grid configuration for 26 letters
    // 6 columns x 5 rows = 30 slots (more than enough for 26)
    const cols = 6;
    const rows = 5;

    // Padding from edges
    const paddingX = 0.10;
    const paddingY = 0.05;

    // Available area
    const availableWidth = 1.0 - (paddingX * 2);
    const availableHeight = 0.88 - paddingY; // Leave space at bottom

    // Cell size
    const cellWidth = availableWidth / cols;
    const cellHeight = availableHeight / rows;

    // Jitter amount (randomness within cell) - smaller = more grid-like
    const jitterX = cellWidth * 0.25;
    const jitterY = cellHeight * 0.20;

    // Generate grid positions and shuffle for randomness
    final gridPositions = <Offset>[];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Calculate base position (center of cell)
        final baseX = paddingX + (col + 0.5) * cellWidth;
        final baseY = paddingY + (row + 0.5) * cellHeight;

        // Add jitter
        final x = baseX + (random.nextDouble() - 0.5) * 2 * jitterX;
        final y = baseY + (random.nextDouble() - 0.5) * 2 * jitterY;

        gridPositions.add(Offset(
          x.clamp(paddingX, 1.0 - paddingX),
          y.clamp(paddingY, 0.88),
        ));
      }
    }

    // Shuffle positions for random letter placement
    gridPositions.shuffle(random);

    // Create letter nodes
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

  // Hit detection radii (relative to container size)
  // Scaled for 26 letters - smaller to avoid overlap
  // Inner radius: immediate selection (must be very close to center)
  static const double _innerHitRadius = 0.035;
  // Outer radius: dwell-time selection (awareness zone)
  static const double _outerHitRadius = 0.055;

  /// Start dragging from a position - check if it hits a letter
  void startDrag(Offset relativePosition) {
    // Reset all tracking state
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    _lastDragPosition = relativePosition;
    _lastDragTime = DateTime.now();

    // For starting, use inner radius (must be intentional)
    final hitNode = _findNodeAtPosition(relativePosition, _innerHitRadius);
    if (hitNode != null) {
      emit(state.copyWith(
        isDragging: true,
        selectedLetterIds: [hitNode.id],
        currentDragPosition: relativePosition,
      ));
    } else {
      // Start dragging even without hitting a letter (allows drag-through)
      emit(state.copyWith(
        isDragging: true,
        currentDragPosition: relativePosition,
      ));
    }
  }

  /// Calculate current movement velocity (relative units per second)
  double _calculateVelocity(Offset currentPosition) {
    if (_lastDragPosition == null || _lastDragTime == null) {
      return 0.0;
    }

    final now = DateTime.now();
    final timeDelta = now.difference(_lastDragTime!).inMicroseconds / 1000000.0;
    if (timeDelta <= 0) return 0.0;

    final dx = currentPosition.dx - _lastDragPosition!.dx;
    final dy = currentPosition.dy - _lastDragPosition!.dy;
    final distance = (dx * dx + dy * dy);
    final speed = distance > 0 ? (distance / timeDelta) : 0.0;

    return speed;
  }

  /// Update drag position and check for new letter hits with sticky/magnetic behavior
  void updateDrag(Offset relativePosition) {
    if (!state.isDragging) return;

    final now = DateTime.now();

    // Calculate velocity to detect pass-through vs intentional selection
    final velocity = _calculateVelocity(relativePosition);
    final isPassingThrough = velocity > _passThroughVelocity;

    // Update tracking for next velocity calculation
    _lastDragPosition = relativePosition;
    _lastDragTime = now;

    // First check inner radius (immediate selection - always triggers)
    final innerHitNode = _findNodeAtPosition(relativePosition, _innerHitRadius);

    // Then check outer radius (dwell-time selection)
    final outerHitNode = _findNodeAtPosition(relativePosition, _outerHitRadius);

    final lastSelectedId = state.selectedLetterIds.isNotEmpty
        ? state.selectedLetterIds.last
        : null;

    // Case 1: Direct hit on inner radius - but still check velocity
    // Only immediate selection if moving slowly (not passing through)
    if (innerHitNode != null && innerHitNode.id != lastSelectedId) {
      if (!isPassingThrough) {
        _confirmLetterSelection(innerHitNode.id, relativePosition);
        return;
      }
      // If passing through inner radius, treat same as outer - need to dwell
    }

    // Case 2: Within outer radius - only track dwell if NOT passing through quickly
    if (outerHitNode != null && outerHitNode.id != lastSelectedId) {
      if (isPassingThrough) {
        // Moving too fast - user is passing through, don't select
        // Reset pending if it was this letter
        if (_pendingLetterId == outerHitNode.id) {
          _pendingLetterId = null;
          _pendingLetterEnteredAt = null;
        }
        emit(state.copyWith(currentDragPosition: relativePosition));
        return;
      }

      // Moving slowly enough - check dwell time
      if (_pendingLetterId == outerHitNode.id) {
        // Same letter as pending - check if dwell time elapsed
        final elapsed = now.difference(_pendingLetterEnteredAt!);
        if (elapsed >= _dwellTime) {
          _confirmLetterSelection(outerHitNode.id, relativePosition);
        } else {
          // Still waiting - just update position
          emit(state.copyWith(currentDragPosition: relativePosition));
        }
      } else {
        // New letter entered outer zone - start tracking
        _pendingLetterId = outerHitNode.id;
        _pendingLetterEnteredAt = now;
        emit(state.copyWith(currentDragPosition: relativePosition));
      }
      return;
    }

    // Case 3: Outside all zones - clear pending and update position
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    emit(state.copyWith(currentDragPosition: relativePosition));
  }

  /// Confirm selection of a letter
  void _confirmLetterSelection(int letterId, Offset position) {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;

    final newSelection = [...state.selectedLetterIds, letterId];
    emit(state.copyWith(
      selectedLetterIds: newSelection,
      currentDragPosition: position,
    ));
  }

  /// End dragging - keep selection intact so user can tap GO or DEL
  void endDrag() {
    // Reset all tracking state
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    _lastDragPosition = null;
    _lastDragTime = null;
    emit(state.copyWith(
      isDragging: false,
      clearDragPosition: true,
    ));
  }

  /// Find a letter node at the given relative position within specified radius
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

  void selectLetter(int letterId) {
    // Check if it's the last one (then deselect)
    if (state.selectedLetterIds.isNotEmpty &&
        state.selectedLetterIds.last == letterId) {
      final newSelection = List<int>.from(state.selectedLetterIds)..removeLast();
      emit(state.copyWith(selectedLetterIds: newSelection));
      return;
    }

    // Add to selection (allow duplicates, just not consecutive)
    final newSelection = [...state.selectedLetterIds, letterId];
    emit(state.copyWith(selectedLetterIds: newSelection));
  }

  void clearSelection() {
    emit(state.copyWith(selectedLetterIds: [], clearDragPosition: true));
  }

  void submitWord() {
    if (state.currentWord.length < 2) return;

    final word = state.currentWord;

    // Alpha Quest validation
    if (state.phase == GamePhase.playingRound && state.currentLetter != null) {
      final isValid = _dictionary.isValidWord(
        word,
        state.category,
        state.currentLetter!,
      );

      if (isValid) {
        _handleCorrectAnswer(word);
      } else {
        _handleWrongAnswer();
      }
    } else {
      // Non-Alpha Quest mode (original behavior)
      final newWords = [...state.completedWords, word];
      final wordScore = state.selectedLetters.fold<int>(0, (sum, l) => sum + l.points);
      emit(state.copyWith(
        completedWords: newWords,
        selectedLetterIds: [],
        score: state.score + wordScore,
      ));
    }
  }

  /// Calculate score for a word (Scrabble-style + bonuses)
  int _calculateWordScore(String word) {
    int score = 0;
    final upperWord = word.toUpperCase();

    // Sum letter points
    for (final char in upperWord.split('')) {
      score += _letterPoints[char] ?? 1;
    }

    // Bonus for longer words
    if (upperWord.length >= 7) {
      score += 10; // Long word bonus
    } else if (upperWord.length >= 5) {
      score += 5; // Medium word bonus
    }

    return score;
  }

  /// Handle correct answer in Alpha Quest
  void _handleCorrectAnswer(String word) {
    final wordScore = _calculateWordScore(word);
    final newScore = state.score + wordScore;
    final newWords = [...state.completedWords, word];
    final nextCategoryIndex = state.categoryIndex + 1;

    // Check if we completed all 5 categories for this letter
    if (nextCategoryIndex >= GameState.categoriesPerLetter) {
      // Letter complete! Move to next letter
      _completeLetterRound(newScore, newWords);
    } else {
      // Move to next category for same letter
      final nextCategory = state.currentCategories[nextCategoryIndex];
      emit(state.copyWith(
        score: newScore,
        completedWords: newWords,
        categoryIndex: nextCategoryIndex,
        category: nextCategory,
        selectedLetterIds: [],
        lastAnswerCorrect: true,
        phase: GamePhase.categoryReveal, // Show jackpot for next category
      ));
    }
  }

  /// Complete a letter round and move to next letter
  void _completeLetterRound(int newScore, List<String> newWords) {
    _timer?.cancel(); // Stop timer for this round

    final newCompletedLetters = [...state.completedLetters, state.currentLetter!];

    // Check if all 25 letters completed (A-Y, no X)
    if (newCompletedLetters.length >= 25) {
      _endGame(isWinner: true, finalScore: newScore);
      return;
    }

    // Move to next letter round
    emit(state.copyWith(
      score: newScore,
      completedWords: newWords,
      completedLetters: newCompletedLetters,
      letterRound: state.letterRound + 1,
      selectedLetterIds: [],
      lastAnswerCorrect: true,
      phase: GamePhase.spinningWheel,
      clearCurrentLetter: true,
      currentCategories: [],
      categoryIndex: 0,
      isPlaying: false, // Timer stops until next wheel spin
    ));
  }

  /// Handle wrong answer - deduct time, keep same category
  void _handleWrongAnswer() {
    // Deduct time penalty for wrong answer
    final newTime = (state.timeRemaining - 5).clamp(0, 999);

    emit(state.copyWith(
      timeRemaining: newTime,
      selectedLetterIds: [],
      lastAnswerCorrect: false,
    ));

    if (newTime <= 0) {
      _endGame(isWinner: false);
    }
  }

  /// End the game
  void _endGame({required bool isWinner, int? finalScore}) {
    _timer?.cancel();
    emit(state.copyWith(
      isPlaying: false,
      phase: GamePhase.gameOver,
      isWinner: isWinner,
      score: finalScore ?? state.score,
    ));
  }

  /// Reset the game to initial state
  void resetGame() {
    _timer?.cancel();
    _initializeLetters();
    emit(state.copyWith(
      phase: GamePhase.notStarted,
      score: 0,
      timeRemaining: 120,
      completedLetters: [],
      completedWords: [],
      letterRound: 1,
      isWinner: false,
      isPlaying: false,
      selectedLetterIds: [],
      clearCurrentLetter: true,
      category: '',
      currentCategories: [],
      categoryIndex: 0,
      clearLastAnswerCorrect: true,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
