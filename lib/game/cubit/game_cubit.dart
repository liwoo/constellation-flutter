import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/shared/models/models.dart';
import 'package:constellation_app/shared/services/services.dart';

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

  // Letter difficulty levels (1 = easiest, 5 = hardest)
  // Based on frequency of words starting with these letters in categories
  static const Map<String, int> _letterDifficulty = {
    // Difficulty 1: Very common starting letters
    'A': 1, 'B': 1, 'C': 1, 'S': 1, 'M': 1, 'P': 1,
    // Difficulty 2: Common starting letters
    'D': 2, 'F': 2, 'G': 2, 'H': 2, 'L': 2, 'R': 2, 'T': 2,
    // Difficulty 3: Moderately common
    'E': 3, 'I': 3, 'J': 3, 'K': 3, 'N': 3, 'O': 3, 'W': 3,
    // Difficulty 4: Less common
    'U': 4, 'V': 4, 'Y': 4,
    // Difficulty 5: Rare starting letters (X excluded from game)
    'Q': 5, 'Z': 5,
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
      timeRemaining: 250, // Start with 250 seconds, carries over between rounds
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
      hintsRemaining: 3, // Start with 3 hints
      clearHintWord: true,
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
    // Audio and haptic feedback for wheel landing
    AudioService.instance.play(GameSound.wheelLand);
    HapticService.instance.heavy();

    final upperLetter = letter.toUpperCase();

    // Get 5 random categories that have words for this letter
    final categories = _get5RandomCategoriesForLetter(upperLetter);

    emit(state.copyWith(
      currentLetter: upperLetter,
      currentCategories: categories,
      categoryIndex: 0,
      category: categories.isNotEmpty ? categories[0] : 'ANIMALS',
      letterRoundStartScore: state.score, // Track score at start of this letter round
      phase: GamePhase.categoryReveal,
      isPlaying: true,
      clearLastAnswerCorrect: true,
    ));

    // Start timer when wheel lands (every round)
    _startTimer();
  }

  /// Called when category jackpot animation completes
  void onCategoryRevealed() {
    emit(state.copyWith(
      phase: GamePhase.playingRound,
      selectedLetterIds: [],
      committedWord: '',
    ));
  }

  /// Get 5 random categories that have words for the letter
  /// Categories are weighted by difficulty based on current round
  List<String> _get5RandomCategoriesForLetter(String letter) {
    // Use weighted selection based on current round
    final weightedCategories = CategoryService.instance.getNRandomCategoriesWeighted(
      letter,
      state.letterRound,
      5,
    );

    if (weightedCategories.isEmpty) {
      // Fallback to unweighted selection
      final validCategories = CategoryDictionary.categories.where((cat) {
        return _dictionary.categoryHasWordsForLetter(cat, letter);
      }).toList();

      if (validCategories.isEmpty) return ['ANIMALS', 'FOOD & DRINK', 'COUNTRIES', 'SPORTS', 'CITIES'];

      validCategories.shuffle(_random);
      return validCategories.take(5).toList();
    }

    return weightedCategories.map((c) => c.name.toUpperCase()).toList();
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
  /// Letters are weighted by difficulty - easier letters appear more often early in the game
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

  /// Get weighted remaining letters for wheel spin
  /// Earlier rounds favor easier letters, later rounds are more random
  List<String> getWeightedRemainingLetters() {
    final remaining = getRemainingLetters();
    if (remaining.isEmpty) return remaining;

    final weightedList = <String>[];
    final currentRound = state.letterRound;

    // Calculate difficulty threshold based on round
    // Round 1-5: prefer difficulty 1-2
    // Round 6-10: prefer difficulty 1-3
    // Round 11-15: prefer difficulty 1-4
    // Round 16+: all difficulties equal
    final maxPreferredDifficulty = switch (currentRound) {
      <= 5 => 2,
      <= 10 => 3,
      <= 15 => 4,
      _ => 5,
    };

    for (final letter in remaining) {
      final difficulty = _letterDifficulty[letter] ?? 3;

      // Calculate weight: easier letters get more entries
      // Weight = (maxPreferredDifficulty - difficulty + 1) clamped to 1-5
      int weight;
      if (difficulty <= maxPreferredDifficulty) {
        // Preferred difficulty range: higher weight for easier
        weight = (maxPreferredDifficulty - difficulty + 2).clamp(1, 5);
      } else {
        // Above preferred difficulty: minimal weight (still possible)
        weight = 1;
      }

      // Add letter multiple times based on weight
      for (var i = 0; i < weight; i++) {
        weightedList.add(letter);
      }
    }

    // Shuffle to randomize
    weightedList.shuffle(_random);
    return weightedList;
  }

  /// Generate all 26 letters in QWERTY keyboard layout
  /// Compact layout anchored to bottom, like a real keyboard
  List<LetterNode> _generateLetterNodes() {
    final letters = <LetterNode>[];

    // QWERTY keyboard rows
    const row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P']; // 10 letters
    const row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];      // 9 letters
    const row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];                // 7 letters

    // Layout configuration - bottom-anchored with comfortable spacing
    const paddingX = 0.05;
    const bottomPadding = 0.18; // Distance from bottom
    const availableWidth = 1.0 - (paddingX * 2);
    const rowSpacing = 0.20; // Comfortable spacing between rows

    // Calculate positions anchored from bottom
    // Row 3 is at bottom, Row 1 is at top of keyboard area
    Map<String, Offset> letterPositions = {};

    // Row 3 (bottom row) - 7 letters, more indent
    const row3Indent = 0.12;
    final row3Width = availableWidth - (row3Indent * 2);
    for (int i = 0; i < row3.length; i++) {
      final x = paddingX + row3Indent + (i + 0.5) * (row3Width / row3.length);
      final y = 1.0 - bottomPadding; // Anchored to bottom
      letterPositions[row3[i]] = Offset(x, y);
    }

    // Row 2 (middle row) - 9 letters, slight indent
    const row2Indent = 0.04;
    final row2Width = availableWidth - (row2Indent * 2);
    for (int i = 0; i < row2.length; i++) {
      final x = paddingX + row2Indent + (i + 0.5) * (row2Width / row2.length);
      final y = 1.0 - bottomPadding - rowSpacing;
      letterPositions[row2[i]] = Offset(x, y);
    }

    // Row 1 (top row) - 10 letters, no indent
    for (int i = 0; i < row1.length; i++) {
      final x = paddingX + (i + 0.5) * (availableWidth / row1.length);
      final y = 1.0 - bottomPadding - rowSpacing * 2;
      letterPositions[row1[i]] = Offset(x, y);
    }

    // Create letter nodes in alphabetical order (for consistent IDs)
    for (int i = 0; i < 26; i++) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
      final points = _letterPoints[letter] ?? 1;
      final position = letterPositions[letter] ?? const Offset(0.5, 0.5);

      letters.add(LetterNode(
        id: i,
        letter: letter,
        points: points,
        position: position,
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
  /// If there's an existing selection (e.g., after pressing x2), continue from it
  void startDrag(Offset relativePosition) {
    // Reset all tracking state
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    _lastDragPosition = relativePosition;
    _lastDragTime = DateTime.now();

    // Check if we already have a selection (e.g., user pressed x2 and wants to continue)
    final hasExistingSelection = state.selectedLetterIds.isNotEmpty;

    // For starting, use inner radius (must be intentional)
    final hitNode = _findNodeAtPosition(relativePosition, _innerHitRadius);

    if (hasExistingSelection) {
      // Continue from existing selection
      if (hitNode != null) {
        final lastId = state.selectedLetterIds.last;
        if (hitNode.id != lastId) {
          // Hit a different letter - add to selection
          final newSelection = [...state.selectedLetterIds, hitNode.id];
          emit(state.copyWith(
            isDragging: true,
            selectedLetterIds: newSelection,
            currentDragPosition: relativePosition,
          ));
        } else {
          // Hit the same letter - just continue dragging
          emit(state.copyWith(
            isDragging: true,
            currentDragPosition: relativePosition,
          ));
        }
      } else {
        // No hit - just start dragging, keep existing selection
        emit(state.copyWith(
          isDragging: true,
          currentDragPosition: relativePosition,
        ));
      }
    } else {
      // No existing selection - start fresh
      if (hitNode != null) {
        // Validate first letter in Alpha Quest mode
        if (state.phase == GamePhase.playingRound && state.currentLetter != null) {
          // First letter (after any committed word) should be valid prefix
          final potentialWord = state.committedWord + hitNode.letter;
          final isValidPath = _dictionary.isValidPrefix(
            potentialWord,
            state.category,
            state.currentLetter!,
          );

          if (!isValidPath) {
            // Invalid starting letter - start dragging without selection
            emit(state.copyWith(
              isDragging: true,
              currentDragPosition: relativePosition,
            ));
            return;
          }
        }

        // Valid starting letter
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

  /// Confirm selection of a letter - only if it could lead to a valid word
  void _confirmLetterSelection(int letterId, Offset position) {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;

    // Only validate in Alpha Quest playing mode
    if (state.phase == GamePhase.playingRound && state.currentLetter != null) {
      // Build the potential new word with this letter
      final newLetter = state.letters.firstWhere((l) => l.id == letterId).letter;
      final potentialWord = state.committedWord + state.currentSelection + newLetter;

      // Check if this prefix could lead to a valid word
      final isValidPath = _dictionary.isValidPrefix(
        potentialWord,
        state.category,
        state.currentLetter!,
      );

      if (!isValidPath) {
        // Invalid path - reject the connection silently
        // Just update drag position without adding letter
        emit(state.copyWith(currentDragPosition: position));
        return;
      }
    }

    // Valid connection - add the letter
    AudioService.instance.play(GameSound.letterSelect);
    HapticService.instance.medium();

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
    emit(state.copyWith(
      selectedLetterIds: [],
      committedWord: '', // Also clear committed word
      clearDragPosition: true,
      spaceUsageCount: 0, // Reset bonus counts
      repeatUsageCount: 0,
    ));
  }

  /// Insert a space - commits current selection and allows fresh start
  /// Awards bonus points for using multi-word answers
  void insertSpace() {
    if (state.selectedLetterIds.isEmpty) return;

    // Commit current selection + space, then clear selection for fresh drag
    final newCommitted = state.committedWord + state.currentSelection + ' ';
    emit(state.copyWith(
      committedWord: newCommitted,
      selectedLetterIds: [], // Clear selection for fresh start
      spaceUsageCount: state.spaceUsageCount + 1, // Track bonus usage
    ));
  }

  /// Repeat the last letter (for double letters like SS in JURASSIC)
  /// Awards bonus points for using x2 feature
  void repeatLastLetter() {
    if (state.selectedLetterIds.isEmpty) return;
    final lastId = state.selectedLetterIds.last;
    // Don't repeat spaces
    if (lastId == GameState.spaceId) return;

    final newSelection = [...state.selectedLetterIds, lastId];
    emit(state.copyWith(
      selectedLetterIds: newSelection,
      repeatUsageCount: state.repeatUsageCount + 1, // Track bonus usage
    ));
  }

  /// Use a hint - animates letters in sequence for a valid word
  /// Returns true if hint was used, false if no hints remaining
  bool useHint() {
    if (state.hintsRemaining <= 0) return false;
    if (state.currentLetter == null) return false;

    // Get a random valid word from the dictionary
    final hintWord = _dictionary.getRandomWord(
      state.category,
      state.currentLetter!,
    );

    if (hintWord == null) return false;

    // Compute the sequence of letter node IDs
    final hintLetterIds = _computeHintLetterSequence(hintWord);
    if (hintLetterIds.isEmpty) return false;

    // Haptic feedback for hint
    HapticService.instance.medium();

    emit(state.copyWith(
      hintsRemaining: state.hintsRemaining - 1,
      hintWord: hintWord,
      hintLetterIds: hintLetterIds,
      hintAnimationIndex: 0,
    ));

    // Animate through the sequence with delays
    _animateHintSequence(hintLetterIds.length);

    return true;
  }

  /// Compute the sequence of letter node IDs for the hint word
  List<int> _computeHintLetterSequence(String word) {
    final sequence = <int>[];
    final upperWord = word.toUpperCase().replaceAll(' ', '');

    for (final char in upperWord.split('')) {
      // Find the letter node for this character
      final node = state.letters.firstWhere(
        (l) => l.letter.toUpperCase() == char,
        orElse: () => const LetterNode(id: -1, letter: '', points: 0, position: Offset.zero),
      );
      if (node.id >= 0) {
        sequence.add(node.id);
      }
    }

    return sequence;
  }

  /// Animate through the hint sequence, highlighting letters one by one
  void _animateHintSequence(int totalLetters) {
    const delayPerLetter = Duration(milliseconds: 400);
    final totalDuration = delayPerLetter * totalLetters + const Duration(milliseconds: 800);

    // Advance through each letter in sequence
    for (int i = 1; i <= totalLetters; i++) {
      Future.delayed(delayPerLetter * i, () {
        if (isClosed) return;
        if (state.hintWord == null) return; // Hint was cleared
        emit(state.copyWith(hintAnimationIndex: i));
      });
    }

    // Clear the hint after full animation
    Future.delayed(totalDuration, () {
      if (isClosed) return;
      emit(state.copyWith(clearHintWord: true));
    });
  }

  /// Clear the hint word (called after animation)
  void clearHint() {
    emit(state.copyWith(clearHintWord: true));
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
      // Filter out nulls (spaces) and sum points
      final wordScore = state.selectedLetters
          .whereType<LetterNode>()
          .fold<int>(0, (sum, l) => sum + l.points);
      emit(state.copyWith(
        completedWords: newWords,
        selectedLetterIds: [],
        committedWord: '',
        score: state.score + wordScore,
      ));
    }
  }

  /// Calculate score for a word (Scrabble-style + bonuses)
  /// Includes bonus points for using space (multi-word) and x2 (double letter) features
  int _calculateWordScore(String word) {
    int score = 0;
    final upperWord = word.toUpperCase();

    // Sum letter points (spaces don't count)
    for (final char in upperWord.split('')) {
      if (char == ' ') continue; // Skip spaces
      score += _letterPoints[char] ?? 1;
    }

    // Count actual letters (excluding spaces) for length bonus
    final letterCount = upperWord.replaceAll(' ', '').length;

    // Bonus for longer words
    if (letterCount >= 7) {
      score += 10; // Long word bonus
    } else if (letterCount >= 5) {
      score += 5; // Medium word bonus
    }

    // Bonus for using space button (multi-word answers like "JURASSIC PARK")
    // +5 points per space used
    score += state.spaceUsageCount * 5;

    // Bonus for using x2 button (double letters like SS in JURASSIC)
    // +3 points per x2 used
    score += state.repeatUsageCount * 3;

    return score;
  }

  /// Handle correct answer in Alpha Quest
  void _handleCorrectAnswer(String word) {
    // Audio and haptic feedback for correct answer
    AudioService.instance.play(GameSound.wordCorrect);
    HapticService.instance.success();

    final wordScore = _calculateWordScore(word);
    final newScore = state.score + wordScore;
    final newWords = [...state.completedWords, word];
    final nextCategoryIndex = state.categoryIndex + 1;

    // Time bonus: +10 seconds per space used (multi-word answers)
    final timeBonus = state.spaceUsageCount * 10;
    final newTime = state.timeRemaining + timeBonus;

    // Extra haptic reward for time bonus
    if (timeBonus > 0) {
      HapticService.instance.doubleTap();
    }

    // First emit celebration state - keep letters visible for animation
    emit(state.copyWith(
      score: newScore,
      timeRemaining: newTime,
      lastAnswerCorrect: true,
      lastTimeBonus: timeBonus > 0 ? timeBonus : null,
      clearLastTimeBonus: timeBonus == 0,
    ));

    // Delay transition to allow celebration animation to play
    Future.delayed(const Duration(milliseconds: 800), () {
      if (isClosed) return; // Guard against cubit being closed

      // Check if we completed all 5 categories for this letter
      if (nextCategoryIndex >= GameState.categoriesPerLetter) {
        // Letter complete! Move to next letter
        // First clear lastAnswerCorrect so the round celebration can re-trigger it
        emit(state.copyWith(clearLastAnswerCorrect: true));
        _completeLetterRound(newScore, newWords);
      } else {
        // Move to next category for same letter
        final nextCategory = state.currentCategories[nextCategoryIndex];
        emit(state.copyWith(
          completedWords: newWords,
          categoryIndex: nextCategoryIndex,
          category: nextCategory,
          selectedLetterIds: [],
          committedWord: '',
          clearLastAnswerCorrect: true,
          clearLastTimeBonus: true,
          phase: GamePhase.categoryReveal, // Show jackpot for next category
          spaceUsageCount: 0, // Reset bonus counts
          repeatUsageCount: 0,
        ));
      }
    });
  }

  /// Complete a letter round and show celebration screen
  /// Time carries over from previous round minus 10 second penalty
  void _completeLetterRound(int newScore, List<String> newWords) {
    final newCompletedLetters = [...state.completedLetters, state.currentLetter!];

    // Check if all 25 letters completed (A-Y, no X)
    if (newCompletedLetters.length >= 25) {
      _endGame(isWinner: true, finalScore: newScore);
      return;
    }

    // STOP the timer during celebration
    _timer?.cancel();

    // Play round complete celebration
    AudioService.instance.play(GameSound.roundComplete);
    HapticService.instance.success();

    // Show letter complete celebration screen
    // Timer is paused, showing current time (deduction happens when continuing)
    emit(state.copyWith(
      score: newScore,
      completedWords: newWords,
      completedLetters: newCompletedLetters,
      selectedLetterIds: [],
      committedWord: '',
      lastAnswerCorrect: true,
      phase: GamePhase.letterComplete, // New celebration phase
      isPlaying: false, // Timer is stopped
      spaceUsageCount: 0,
      repeatUsageCount: 0,
      hintsRemaining: state.hintsRemaining + 1, // Award extra hint for completing letter
    ));
  }

  /// Continue to next round after letter complete celebration
  /// Called when user taps "Continue" on the celebration screen
  void continueToNextRound() {
    // Time bonus: double remaining time + points earned in round
    // e.g., 20s remaining + 70pts = (20 * 2) + 70 = 110s
    final newTime = (state.timeRemaining * 2) + state.pointsEarnedInRound;

    // Move to next letter round - timer stays paused until wheel lands
    emit(state.copyWith(
      letterRound: state.letterRound + 1,
      timeRemaining: newTime,
      clearLastAnswerCorrect: true,
      phase: GamePhase.spinningWheel,
      clearCurrentLetter: true,
      currentCategories: [],
      categoryIndex: 0,
      isPlaying: false, // Timer paused until wheel lands
    ));
    // Note: Timer will start in onWheelLanded()
  }

  /// Handle wrong answer - deduct time, keep same category
  /// Preserves banked words (committedWord) so only the current selection is lost
  void _handleWrongAnswer() {
    // Audio and haptic feedback for wrong answer
    AudioService.instance.play(GameSound.wordWrong);
    HapticService.instance.error();

    // Deduct time penalty for wrong answer
    final newTime = (state.timeRemaining - 5).clamp(0, 999);

    // Only clear current selection, keep banked words (committedWord) safe
    emit(state.copyWith(
      timeRemaining: newTime,
      selectedLetterIds: [], // Clear current drag selection
      // Note: committedWord is preserved - banked words are safe!
      lastAnswerCorrect: false,
      // Don't reset spaceUsageCount - banked spaces are still valid
      repeatUsageCount: 0, // Only reset repeat count for current selection
    ));

    if (newTime <= 0) {
      _endGame(isWinner: false);
    }
  }

  /// End the game
  void _endGame({required bool isWinner, int? finalScore}) {
    _timer?.cancel();

    final score = finalScore ?? state.score;

    // Audio and haptic feedback for game end
    if (isWinner) {
      AudioService.instance.play(GameSound.gameWin);
      HapticService.instance.success();
    } else {
      AudioService.instance.play(GameSound.gameLose);
      HapticService.instance.warning();
    }

    // Save game session to local storage
    _saveGameSession(score, isWinner);

    emit(state.copyWith(
      isPlaying: false,
      phase: GamePhase.gameOver,
      isWinner: isWinner,
      score: score,
    ));
  }

  /// Save the completed game session to local storage
  Future<void> _saveGameSession(int score, bool isWinner) async {
    final session = GameSession.create(
      score: score,
      lettersCompleted: state.completedLetters.length,
      wordsCompleted: state.completedWords.length,
      isWinner: isWinner,
    );
    await StorageService.instance.saveGameSession(session);
  }

  /// Reset the game to initial state
  void resetGame() {
    _timer?.cancel();
    _initializeLetters();
    emit(state.copyWith(
      phase: GamePhase.notStarted,
      score: 0,
      timeRemaining: 250, // Reset to starting time
      completedLetters: [],
      completedWords: [],
      letterRound: 1,
      isWinner: false,
      isPlaying: false,
      selectedLetterIds: [],
      committedWord: '',
      clearCurrentLetter: true,
      category: '',
      currentCategories: [],
      categoryIndex: 0,
      clearLastAnswerCorrect: true,
      hintsRemaining: 3, // Reset hints
      clearHintWord: true,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
