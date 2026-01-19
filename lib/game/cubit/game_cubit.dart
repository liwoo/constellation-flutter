import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/shared/constants/constants.dart';
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

  // Hit detection config from constants
  static const Duration _dwellTime = Duration(seconds: HitDetectionConfig.dwellTimeSeconds);
  static const double _passThroughVelocity = HitDetectionConfig.passThroughVelocity;

  // Mystery orb count based on round (from constants)
  int get _mysteryOrbCount => MysteryOrbConfig.getOrbCount(state.letterRound);

  // Mystery outcome probabilities from constants
  static const Map<MysteryOutcome, int> _mysteryOutcomeProbabilities = {
    MysteryOutcome.timeBonus: MysteryOrbConfig.timeBonusProbability,
    MysteryOutcome.scoreMultiplier: MysteryOrbConfig.scoreMultiplierProbability,
    MysteryOutcome.freeHint: MysteryOrbConfig.freeHintProbability,
    MysteryOutcome.timePenalty: MysteryOrbConfig.timePenaltyProbability,
    MysteryOutcome.scrambleLetters: MysteryOrbConfig.scrambleLettersProbability,
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
      timeRemaining: GameConfig.startingTime,
      score: 0,
      letterRound: 1,
      letterRoundStartScore: 0,
      completedLetters: [],
      isPlaying: false,
      isWinner: false,
      phase: GamePhase.spinningWheel,
      clearCurrentLetter: true,
      category: '',
      currentCategories: [],
      categoryIndex: 0,
      clearLastAnswerCorrect: true,
      hintsRemaining: GameConfig.startingHints,
      clearHintWord: true,
      // Reset mystery orb state
      mysteryOrbs: [],
      consecutivePenalties: 0,
      scoreMultiplierActive: false,
      clearLastMysteryOutcome: true,
      clearPendingMysteryOrb: true,
      clearMysteryOrbDwellStartTime: true,
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
    // Generate letters AND mystery orbs together in the same grid (like Scrabble blanks)
    final result = _generateLettersAndMysteryOrbs(
      state.category,
      state.currentLetter!,
    );

    emit(state.copyWith(
      phase: GamePhase.playingRound,
      selectedLetterIds: [],
      committedWord: '',
      letters: result.letters,
      mysteryOrbs: result.mysteryOrbs, // Already active, part of the grid
      clearPendingMysteryOrb: true,
      clearMysteryOrbDwellStartTime: true,
    ));
  }

  /// Get all unique letters needed for valid words in this category/letter round
  Set<String> _getLettersForRound(String category, String letter) {
    final words = _dictionary.getWordsForCategoryAndLetter(category, letter);
    final letters = <String>{};

    for (final word in words) {
      // Extract all letters (ignore spaces, convert to uppercase)
      for (final char in word.toUpperCase().split('')) {
        if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
          letters.add(char);
        }
      }
    }

    return letters;
  }

  /// Generate letter nodes only for letters needed in this round
  /// Uses randomized grid placement (not QWERTY)
  /// Mystery orbs REPLACE actual letters (prioritizing vowels) - like Scrabble blanks
  /// This forces players to use mystery orbs as wildcards to complete words
  ({List<LetterNode> letters, List<MysteryOrb> mysteryOrbs}) _generateLettersAndMysteryOrbs(String category, String letter) {
    final neededLetters = _getLettersForRound(category, letter).toList();
    neededLetters.sort(); // Sort alphabetically for consistent IDs

    // Identify letters to replace with mystery orbs (prioritize vowels)
    // This creates jeopardy - players MUST use mystery blanks to complete words
    // NEVER replace the starting letter - player must be able to start their word
    final vowels = ['A', 'E', 'I', 'O', 'U'];
    final lettersToReplace = <String>[];

    // First, try to replace vowels that exist in the needed letters
    // Skip the starting letter even if it's a vowel
    for (final vowel in vowels) {
      if (vowel == letter) continue; // Never replace the starting letter!
      if (neededLetters.contains(vowel) && lettersToReplace.length < _mysteryOrbCount) {
        lettersToReplace.add(vowel);
      }
    }

    // If we still need more, replace other letters (avoid the starting letter)
    if (lettersToReplace.length < _mysteryOrbCount) {
      final nonVowels = neededLetters.where((l) =>
        !vowels.contains(l) && l != letter // Don't replace the starting letter
      ).toList();
      nonVowels.shuffle(_random);

      for (final l in nonVowels) {
        if (lettersToReplace.length >= _mysteryOrbCount) break;
        lettersToReplace.add(l);
      }
    }

    // Remove replaced letters from the needed letters list
    final remainingLetters = neededLetters.where((l) => !lettersToReplace.contains(l)).toList();

    final letters = <LetterNode>[];
    final mysteryOrbs = <MysteryOrb>[];

    // Total items stays the same (mystery orbs replace letters, not add to them)
    final totalItems = neededLetters.length; // Same count as original

    // Grid configuration based on total number of items
    final cols = totalItems <= 9 ? 3 : (totalItems <= 16 ? 4 : (totalItems <= 25 ? 5 : 6));
    final rows = (totalItems / cols).ceil();

    // Padding from edges
    const paddingX = 0.08;
    const paddingY = 0.08;

    // Available area
    const availableWidth = 1.0 - (paddingX * 2);
    const availableHeight = 0.84 - paddingY;

    // Cell size
    final cellWidth = availableWidth / cols;
    final cellHeight = availableHeight / rows;

    // Jitter amount (randomness within cell)
    final jitterX = cellWidth * 0.20;
    final jitterY = cellHeight * 0.20;

    // Generate grid positions for ALL items
    final gridPositions = <Offset>[];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (gridPositions.length >= totalItems) break;

        // Calculate base position (center of cell)
        final baseX = paddingX + (col + 0.5) * cellWidth;
        final baseY = paddingY + (row + 0.5) * cellHeight;

        // Add jitter
        final x = baseX + (_random.nextDouble() - 0.5) * 2 * jitterX;
        final y = baseY + (_random.nextDouble() - 0.5) * 2 * jitterY;

        gridPositions.add(Offset(
          x.clamp(paddingX, 1.0 - paddingX),
          y.clamp(paddingY, 0.84),
        ));
      }
    }

    // Shuffle positions for random placement
    gridPositions.shuffle(_random);

    // Create letter nodes for remaining letters
    int positionIndex = 0;
    for (final letterChar in remainingLetters) {
      final points = LetterPoints.values[letterChar] ?? 1;
      // Use alphabetical index as ID for consistency
      final id = letterChar.codeUnitAt(0) - 'A'.codeUnitAt(0);

      letters.add(LetterNode(
        id: id,
        letter: letterChar,
        points: points,
        position: gridPositions[positionIndex],
      ));
      positionIndex++;
    }

    // Create mystery orbs that REPLACE the removed letters
    // Each orb tracks which letter it replaces (for word validation)
    for (int i = 0; i < lettersToReplace.length; i++) {
      if (positionIndex < gridPositions.length) {
        mysteryOrbs.add(MysteryOrb(
          id: 100 + i, // IDs 100+ to avoid conflict with letter IDs
          position: gridPositions[positionIndex],
          isActive: true,
          replacedLetter: lettersToReplace[i], // Track which letter this blank represents
        ));
        positionIndex++;
      }
    }

    return (letters: letters, mysteryOrbs: mysteryOrbs);
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
  /// Earlier rounds completely exclude tough letters, later rounds are more random
  List<String> getWeightedRemainingLetters() {
    final remaining = getRemainingLetters();
    if (remaining.isEmpty) return remaining;

    final weightedList = <String>[];
    final currentRound = state.letterRound;

    // Get difficulty thresholds from config
    final maxAllowedDifficulty = DifficultyConfig.getMaxDifficulty(currentRound);
    final maxPreferredDifficulty = DifficultyConfig.getMaxPreferredDifficulty(currentRound);

    for (final letter in remaining) {
      final difficulty = DifficultyConfig.letterDifficulty[letter] ?? 3;

      // Skip letters that are too difficult for current round
      if (difficulty > maxAllowedDifficulty) {
        continue;
      }

      // Calculate weight: easier letters get more entries
      int weight;
      if (difficulty <= maxPreferredDifficulty) {
        // Preferred difficulty range: higher weight for easier
        weight = (maxPreferredDifficulty - difficulty + 2).clamp(1, 5);
      } else {
        // Above preferred but still allowed: minimal weight
        weight = 1;
      }

      // Add letter multiple times based on weight
      for (var i = 0; i < weight; i++) {
        weightedList.add(letter);
      }
    }

    // If all remaining letters were filtered out (late game edge case),
    // fall back to returning whatever is left
    if (weightedList.isEmpty && remaining.isNotEmpty) {
      return remaining;
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
      final points = LetterPoints.values[letter] ?? 1;
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
  // Larger radii now that we have fewer, more spread out letters
  // Hit radii from constants
  static const double _innerHitRadius = HitDetectionConfig.innerHitRadius;
  static const double _outerHitRadius = HitDetectionConfig.outerHitRadius;

  /// Start dragging from a position - check if it hits a letter or mystery orb
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
    // Check for both letters AND mystery orbs
    final hit = _findSelectableAtPosition(relativePosition, _innerHitRadius);

    if (hasExistingSelection) {
      // Continue from existing selection
      // NOTE: We preserve isPureConnection here because the user might have
      // just tapped x2 or space button. Only direct letter taps break pure connection.
      if (hit != null) {
        final lastId = state.selectedLetterIds.last;
        if (hit.id != lastId) {
          // Hit a different letter/orb - this is a TAP, breaks pure connection
          emit(state.copyWith(
            isDragging: true,
            currentDragPosition: relativePosition,
            isPureConnection: false, // Tapping a letter breaks pure connection
          ));
          _confirmSelection(hit.id, hit.letter, hit.isOrb, relativePosition);
        } else {
          // Hit the same letter - TAP TO REPEAT (like x2 but no bonus)
          // This breaks pure connection since it's a tap
          if (!hit.isOrb) {
            // Add the same letter again (allows "SS" by tapping S twice)
            final newSelection = [...state.selectedLetterIds, hit.id];
            emit(state.copyWith(
              isDragging: true,
              currentDragPosition: relativePosition,
              selectedLetterIds: newSelection,
              isPureConnection: false, // Tapping breaks pure connection
            ));
            HapticService.instance.light();
          } else {
            // Can't repeat mystery orbs - just continue
            emit(state.copyWith(
              isDragging: true,
              currentDragPosition: relativePosition,
            ));
          }
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
      if (hit != null) {
        // Validate first letter in Alpha Quest mode - but skip for mystery orbs
        // Mystery orbs are wildcards and can start anywhere
        if (!hit.isOrb && state.phase == GamePhase.playingRound && state.currentLetter != null) {
          final potentialWord = state.committedWord + hit.letter;
          final isValidPath = _dictionary.isValidPrefix(
            potentialWord,
            state.category,
            state.currentLetter!,
          );

          if (!isValidPath) {
            emit(state.copyWith(
              isDragging: true,
              currentDragPosition: relativePosition,
            ));
            return;
          }
        }

        // Valid starting letter/orb - add to selection and trigger orb effect if needed
        // Don't set isPureConnection yet - it's only true if user DRAGS through letters
        // If they just tap letters, it stays false
        emit(state.copyWith(
          isDragging: true,
          currentDragPosition: relativePosition,
          isPureConnection: false, // Will become true only if user drags to add more letters
        ));

        // Handle mystery orb selection (triggers effect on first use)
        if (hit.isOrb) {
          _handleMysteryOrbFirstSelection(hit.id, relativePosition);
        } else {
          emit(state.copyWith(
            selectedLetterIds: [hit.id],
          ));
        }
      } else {
        // Start dragging even without hitting a letter (allows drag-through)
        emit(state.copyWith(
          isDragging: true,
          currentDragPosition: relativePosition,
        ));
      }
    }
  }

  /// Handle first selection of a mystery orb (triggers effect)
  void _handleMysteryOrbFirstSelection(int orbId, Offset position) {
    final orbIndex = state.mysteryOrbs.indexWhere((o) => o.id == orbId);
    if (orbIndex < 0) return;

    final orb = state.mysteryOrbs[orbIndex];

    // Add orb to selection
    final newSelection = [...state.selectedLetterIds, orbId];

    // Check if this orb's effect has already been triggered
    if (!orb.effectTriggered) {
      // Mark orb as effect triggered
      final updatedOrbs = state.mysteryOrbs.map((o) {
        if (o.id == orbId) {
          return o.copyWith(effectTriggered: true);
        }
        return o;
      }).toList();

      // Determine and apply mystery outcome
      final outcome = _determineMysteryOutcome();

      // Play mystery activate sound
      AudioService.instance.play(GameSound.mysteryActivate);
      HapticService.instance.heavy();

      emit(state.copyWith(
        selectedLetterIds: newSelection,
        mysteryOrbs: updatedOrbs,
        lastMysteryOutcome: outcome,
      ));

      // Apply the outcome effects
      _applyMysteryOutcomeEffects(outcome);
    } else {
      // Already triggered - just add to selection
      emit(state.copyWith(
        selectedLetterIds: newSelection,
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

  /// Update drag position and check for new letter/orb hits with sticky/magnetic behavior
  /// Mystery orbs are now selectable as part of the word (they act as wildcards)
  void updateDrag(Offset relativePosition) {
    if (!state.isDragging) return;

    final now = DateTime.now();

    // Calculate velocity to detect pass-through vs intentional selection
    final velocity = _calculateVelocity(relativePosition);
    final isPassingThrough = velocity > _passThroughVelocity;

    // Update tracking for next velocity calculation
    _lastDragPosition = relativePosition;
    _lastDragTime = now;

    // Check for letters AND mystery orbs (both are selectable now)
    final innerHit = _findSelectableAtPosition(relativePosition, _innerHitRadius);
    final outerHit = _findSelectableAtPosition(relativePosition, _outerHitRadius);

    final lastSelectedId = state.selectedLetterIds.isNotEmpty
        ? state.selectedLetterIds.last
        : null;

    // Case 1: Direct hit on inner radius - but still check velocity
    // Only immediate selection if moving slowly (not passing through)
    if (innerHit != null && innerHit.id != lastSelectedId) {
      if (!isPassingThrough) {
        _confirmSelection(innerHit.id, innerHit.letter, innerHit.isOrb, relativePosition, fromDrag: true);
        return;
      }
      // If passing through inner radius, treat same as outer - need to dwell
    }

    // Case 2: Within outer radius - only track dwell if NOT passing through quickly
    if (outerHit != null && outerHit.id != lastSelectedId) {
      if (isPassingThrough) {
        // Moving too fast - user is passing through, don't select
        // Reset pending if it was this item
        if (_pendingLetterId == outerHit.id) {
          _pendingLetterId = null;
          _pendingLetterEnteredAt = null;
        }
        emit(state.copyWith(
          currentDragPosition: relativePosition,
          approachingLetterIds: [], // Clear approaching when passing through
          clearPendingMysteryOrb: true,
          clearMysteryOrbDwellStartTime: true,
        ));
        return;
      }

      // Moving slowly enough - check dwell time
      if (_pendingLetterId == outerHit.id) {
        // Same item as pending - check if dwell time elapsed
        final elapsed = now.difference(_pendingLetterEnteredAt!);
        if (elapsed >= _dwellTime) {
          _confirmSelection(outerHit.id, outerHit.letter, outerHit.isOrb, relativePosition, fromDrag: true);
        } else {
          // Still waiting - show approaching state
          // For orbs, also track orb dwell separately for visual feedback
          if (outerHit.isOrb) {
            emit(state.copyWith(
              currentDragPosition: relativePosition,
              approachingLetterIds: [], // Don't highlight orbs in letter list
              pendingMysteryOrbId: outerHit.id,
              mysteryOrbDwellStartTime: state.mysteryOrbDwellStartTime ?? now,
            ));
          } else {
            emit(state.copyWith(
              currentDragPosition: relativePosition,
              approachingLetterIds: [outerHit.id],
              clearPendingMysteryOrb: true,
              clearMysteryOrbDwellStartTime: true,
            ));
          }
        }
      } else {
        // New item entered outer zone - start tracking
        _pendingLetterId = outerHit.id;
        _pendingLetterEnteredAt = now;
        if (outerHit.isOrb) {
          emit(state.copyWith(
            currentDragPosition: relativePosition,
            approachingLetterIds: [],
            pendingMysteryOrbId: outerHit.id,
            mysteryOrbDwellStartTime: now,
          ));
        } else {
          emit(state.copyWith(
            currentDragPosition: relativePosition,
            approachingLetterIds: [outerHit.id],
            clearPendingMysteryOrb: true,
            clearMysteryOrbDwellStartTime: true,
          ));
        }
      }
      return;
    }

    // Case 3: Outside all zones - clear pending and update position
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    emit(state.copyWith(
      currentDragPosition: relativePosition,
      approachingLetterIds: [], // Clear approaching when outside
      clearPendingMysteryOrb: true,
      clearMysteryOrbDwellStartTime: true,
    ));
  }

  /// Confirm selection of a letter OR mystery orb
  /// Mystery orbs are TRUE WILDCARDS - always connectable, validation at submit time
  /// [fromDrag] indicates if this came from dragging (true) or tapping (false)
  /// Only dragging maintains pure connection status
  void _confirmSelection(int id, String letter, bool isOrb, Offset position, {bool fromDrag = false}) {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;

    // Skip ALL prefix validation if:
    // 1. This is a mystery orb, OR
    // 2. Selection already contains a wildcard (can't validate patterns mid-word)
    final hasWildcard = state.currentSelection.contains(GameState.wildcardChar);
    final shouldSkipValidation = isOrb || hasWildcard;

    if (!shouldSkipValidation && state.phase == GamePhase.playingRound && state.currentLetter != null) {
      final potentialWord = state.committedWord + state.currentSelection + letter;

      final isValidPath = _dictionary.isValidPrefix(
        potentialWord,
        state.category,
        state.currentLetter!,
      );

      if (!isValidPath) {
        emit(state.copyWith(
          currentDragPosition: position,
          clearPendingMysteryOrb: true,
          clearMysteryOrbDwellStartTime: true,
        ));
        return;
      }
    }

    // Valid connection - add the item
    AudioService.instance.play(GameSound.letterSelect);
    HapticService.instance.medium();

    final newSelection = [...state.selectedLetterIds, id];

    // If it's a mystery orb being selected, trigger its effect (only if not already triggered)
    if (isOrb) {
      final orbIndex = state.mysteryOrbs.indexWhere((o) => o.id == id);
      if (orbIndex >= 0) {
        final orb = state.mysteryOrbs[orbIndex];

        // Check if this orb's effect has already been triggered
        if (!orb.effectTriggered) {
          // Mark orb as effect triggered (but still active for word building)
          final updatedOrbs = state.mysteryOrbs.map((o) {
            if (o.id == id) {
              return o.copyWith(effectTriggered: true);
            }
            return o;
          }).toList();

          // Determine and apply mystery outcome
          final outcome = _determineMysteryOutcome();

          // Play mystery activate sound
          AudioService.instance.play(GameSound.mysteryActivate);
          HapticService.instance.heavy();

          emit(state.copyWith(
            selectedLetterIds: newSelection,
            currentDragPosition: position,
            approachingLetterIds: [],
            mysteryOrbs: updatedOrbs,
            clearPendingMysteryOrb: true,
            clearMysteryOrbDwellStartTime: true,
            lastMysteryOutcome: outcome,
            // Only set pure connection if dragging through letters (not tapping)
            isPureConnection: fromDrag ? true : false,
          ));

          // Apply the outcome effects (delayed to not interrupt selection)
          _applyMysteryOutcomeEffects(outcome);
          return;
        }
      }
    }

    emit(state.copyWith(
      selectedLetterIds: newSelection,
      currentDragPosition: position,
      approachingLetterIds: [],
      clearPendingMysteryOrb: true,
      // Only set pure connection if dragging through letters (not tapping)
      isPureConnection: fromDrag ? true : false,
      clearMysteryOrbDwellStartTime: true,
    ));
  }

  /// Apply mystery outcome effects (without updating orb list - already done)
  void _applyMysteryOutcomeEffects(MysteryOutcome outcome) {
    switch (outcome) {
      case MysteryOutcome.timeBonus:
        // Time bonus from mystery orb
        AudioService.instance.play(GameSound.mysteryReward);
        emit(state.copyWith(
          timeRemaining: state.timeRemaining + TimeConfig.mysteryTimeBonus,
          consecutivePenalties: 0,
        ));
        break;

      case MysteryOutcome.scoreMultiplier:
        // 1.5x on next word
        AudioService.instance.play(GameSound.mysteryReward);
        HapticService.instance.doubleTap();
        emit(state.copyWith(
          scoreMultiplierActive: true,
          consecutivePenalties: 0,
        ));
        break;

      case MysteryOutcome.freeHint:
        // Award a free hint
        AudioService.instance.play(GameSound.mysteryReward);
        emit(state.copyWith(
          hintsRemaining: state.hintsRemaining + 1,
          consecutivePenalties: 0,
        ));
        break;

      case MysteryOutcome.timePenalty:
        // Time penalty from mystery orb
        AudioService.instance.play(GameSound.mysteryPenalty);
        HapticService.instance.error();
        final newTime = (state.timeRemaining - TimeConfig.mysteryTimePenalty).clamp(0, 999);
        emit(state.copyWith(
          timeRemaining: newTime,
          consecutivePenalties: state.consecutivePenalties + 1,
        ));
        if (newTime <= 0) {
          _endGame(isWinner: false);
        }
        break;

      case MysteryOutcome.scrambleLetters:
        // Scramble letter positions
        AudioService.instance.play(GameSound.mysteryPenalty);
        HapticService.instance.warning();
        final scrambledLetters = _scrambleLetterPositions();
        emit(state.copyWith(
          letters: scrambledLetters,
          consecutivePenalties: state.consecutivePenalties + 1,
        ));
        break;
    }

    // Clear the outcome feedback after delay
    Future.delayed(const Duration(milliseconds: AnimationConfig.mysteryOutcomeDisplayDuration), () {
      if (isClosed) return;
      emit(state.copyWith(clearLastMysteryOutcome: true));
    });
  }

  /// End dragging - keep selection intact so user can tap GO or DEL
  /// isPureConnection is preserved - it will be checked at submit time
  void endDrag() {
    // Reset all tracking state
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    _lastDragPosition = null;
    _lastDragTime = null;

    // DON'T modify isPureConnection here - let it carry through to submit
    // The user may have dragged all letters in one motion and is now submitting
    emit(state.copyWith(
      isDragging: false,
      clearDragPosition: true,
      approachingLetterIds: [], // Clear approaching state
    ));
  }

  /// Find a letter node OR mystery orb at the given position
  /// Returns (letterId, isOrb) where letterId is the id and isOrb indicates if it's a mystery orb
  ({int id, bool isOrb, String letter, Offset position})? _findSelectableAtPosition(Offset position, double radius) {
    // First check letters
    for (final node in state.letters) {
      final dx = (node.position.dx - position.dx).abs();
      final dy = (node.position.dy - position.dy).abs();
      final distanceSquared = (dx * dx + dy * dy);
      if (distanceSquared < radius * radius) {
        return (id: node.id, isOrb: false, letter: node.letter, position: node.position);
      }
    }

    // Then check mystery orbs (they act as their replacedLetter)
    for (final orb in state.mysteryOrbs) {
      if (!orb.isActive) continue;
      final dx = (orb.position.dx - position.dx).abs();
      final dy = (orb.position.dy - position.dy).abs();
      final distanceSquared = (dx * dx + dy * dy);
      if (distanceSquared < radius * radius) {
        return (id: orb.id, isOrb: true, letter: orb.replacedLetter, position: orb.position);
      }
    }

    return null;
  }

  void selectLetter(int letterId) {
    // Add letter to selection - allows consecutive duplicates (like tapping S twice for SS)
    // This works like the x2 button but without the bonus points
    // Tapping letters breaks pure connection (only dragging maintains it)
    final newSelection = [...state.selectedLetterIds, letterId];
    emit(state.copyWith(
      selectedLetterIds: newSelection,
      isPureConnection: false, // Tapping breaks pure connection
    ));
  }

  void clearSelection() {
    emit(state.copyWith(
      selectedLetterIds: [],
      committedWord: '', // Also clear committed word
      clearDragPosition: true,
      spaceUsageCount: 0, // Reset bonus counts
      repeatUsageCount: 0,
      isPureConnection: false, // Reset pure connection tracking
      showConnectionAnimation: false,
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

  // Hint configuration from constants
  static const int _minTimeForHint = TimeConfig.minTimeForHint;
  static const int _hintTimeCost = TimeConfig.hintTimeCost;

  /// Use a hint - animates letters in sequence for a valid word
  /// Returns true if hint was used, false if no hints remaining or not enough time
  bool useHint() {
    if (state.hintsRemaining <= 0) return false;
    if (state.currentLetter == null) return false;
    // Don't allow hints with less than 15 seconds remaining
    if (state.timeRemaining < _minTimeForHint) return false;

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

    // Deduct 10 seconds for using a hint
    final newTime = state.timeRemaining - _hintTimeCost;

    emit(state.copyWith(
      hintsRemaining: state.hintsRemaining - 1,
      hintWord: hintWord,
      hintLetterIds: hintLetterIds,
      hintAnimationIndex: 0,
      timeRemaining: newTime,
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
    const delayPerLetter = Duration(milliseconds: AnimationConfig.hintLetterRevealDelay);
    final totalDuration = delayPerLetter * totalLetters + const Duration(milliseconds: AnimationConfig.hintCompletionBuffer);

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

    final pattern = state.currentWord; // May contain '*' wildcards

    // Alpha Quest validation
    if (state.phase == GamePhase.playingRound && state.currentLetter != null) {
      // Check if pattern contains wildcards (mystery orbs)
      if (pattern.contains(GameState.wildcardChar)) {
        // Find a matching word where wildcards can be any letter
        final matchedWord = _findMatchingWord(pattern, state.category, state.currentLetter!);
        if (matchedWord != null) {
          _handleCorrectAnswer(matchedWord); // Use the actual matched word
        } else {
          _handleWrongAnswer();
        }
      } else {
        // No wildcards - direct validation
        final isValid = _dictionary.isValidWord(
          pattern,
          state.category,
          state.currentLetter!,
        );

        if (isValid) {
          _handleCorrectAnswer(pattern);
        } else {
          _handleWrongAnswer();
        }
      }
    } else {
      // Non-Alpha Quest mode (original behavior)
      final newWords = [...state.completedWords, pattern];
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

  /// Find a valid word that matches the pattern with wildcards
  /// Returns the matched word or null if no match
  String? _findMatchingWord(String pattern, String category, String startLetter) {
    final validWords = _dictionary.getWordsForCategoryAndLetter(category, startLetter);
    final upperPattern = pattern.toUpperCase();

    for (final word in validWords) {
      final upperWord = word.toUpperCase().replaceAll(' ', '');
      final patternNoSpaces = upperPattern.replaceAll(' ', '');

      if (_matchesPattern(upperWord, patternNoSpaces)) {
        return word;
      }
    }
    return null;
  }

  /// Check if a word matches a pattern with '*' wildcards
  bool _matchesPattern(String word, String pattern) {
    if (word.length != pattern.length) return false;

    for (int i = 0; i < pattern.length; i++) {
      final patternChar = pattern[i];
      final wordChar = word[i];

      // Wildcard matches any character
      if (patternChar == GameState.wildcardChar) continue;

      // Non-wildcard must match exactly
      if (patternChar != wordChar) return false;
    }
    return true;
  }

  /// Calculate score for a word (Scrabble-style + bonuses)
  /// Includes bonus points for using space (multi-word) and x2 (double letter) features
  int _calculateWordScore(String word) {
    int score = 0;
    final upperWord = word.toUpperCase();

    // Sum letter points (spaces don't count)
    for (final char in upperWord.split('')) {
      if (char == ' ') continue; // Skip spaces
      score += LetterPoints.values[char] ?? 1;
    }

    // Count actual letters (excluding spaces) for length bonus
    final letterCount = upperWord.replaceAll(' ', '').length;

    // Bonus for longer words
    if (letterCount >= ScoringConfig.longWordThreshold) {
      score += ScoringConfig.longWordBonus;
    } else if (letterCount >= ScoringConfig.mediumWordThreshold) {
      score += ScoringConfig.mediumWordBonus;
    }

    // Bonus for using space button (multi-word answers like "JURASSIC PARK")
    score += state.spaceUsageCount * ScoringConfig.spacePointsBonus;

    // Bonus for using x2 button (double letters like SS in JURASSIC)
    score += state.repeatUsageCount * ScoringConfig.repeatPointsBonus;

    return score;
  }

  /// Handle correct answer in Alpha Quest
  void _handleCorrectAnswer(String word) {
    // Audio and haptic feedback for correct answer
    AudioService.instance.play(GameSound.wordCorrect);
    HapticService.instance.success();

    var wordScore = _calculateWordScore(word);

    // Apply score multiplier if active (from mystery orb)
    if (state.scoreMultiplierActive) {
      wordScore = (wordScore * ScoringConfig.mysteryScoreMultiplier).round();
    }

    final newScore = state.score + wordScore;
    final newWords = [...state.completedWords, word];
    final nextCategoryIndex = state.categoryIndex + 1;

    // Time bonus for space usage
    var timeBonus = state.spaceUsageCount * TimeConfig.spaceTimeBonus;

    // Pure connection bonus for completing word in single drag
    final wasPureConnection = state.isPureConnection;
    if (wasPureConnection) {
      timeBonus += TimeConfig.pureConnectionBonus;
    }

    final newTime = state.timeRemaining + timeBonus;

    // Dramatic haptic feedback for pure connection, simpler for regular time bonus
    if (wasPureConnection) {
      // Triple burst haptic for pure connection celebration
      HapticService.instance.success();
      Future.delayed(const Duration(milliseconds: AnimationConfig.hapticBurstDelay1), () {
        HapticService.instance.medium();
      });
      Future.delayed(const Duration(milliseconds: AnimationConfig.hapticBurstDelay2), () {
        HapticService.instance.success();
      });
    } else if (timeBonus > 0) {
      HapticService.instance.doubleTap();
    }

    // First emit celebration state - keep letters visible for animation
    // Show connection animation if this was a pure connection
    emit(state.copyWith(
      score: newScore,
      timeRemaining: newTime,
      lastAnswerCorrect: true,
      lastTimeBonus: timeBonus > 0 ? timeBonus : null,
      clearLastTimeBonus: timeBonus == 0,
      scoreMultiplierActive: false,
      showConnectionAnimation: wasPureConnection,
      isPureConnection: false,
    ));

    // Delay transition to allow celebration animation to play
    final celebrationDelay = wasPureConnection
        ? AnimationConfig.pureConnectionCelebrationDelay
        : AnimationConfig.normalCelebrationDelay;
    Future.delayed(Duration(milliseconds: celebrationDelay), () {
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
          showConnectionAnimation: false, // Clear animation flag for next word
        ));
      }
    });
  }

  /// Complete a letter round and show celebration screen
  /// Time carries over from previous round minus 10 second penalty
  void _completeLetterRound(int newScore, List<String> newWords) {
    final newCompletedLetters = [...state.completedLetters, state.currentLetter!];

    // Check if all letters completed (A-Y, no X)
    if (newCompletedLetters.length >= GameConfig.totalLetters) {
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
      showConnectionAnimation: false, // Clear animation flag
    ));
  }

  /// Continue to next round after letter complete celebration
  /// Called when user taps "Continue" on the celebration screen
  void continueToNextRound() {
    // Time bonus with clutch multiplier for low time finishes
    // ≤10s: 2x time, 11-20s: 1.5x time, >20s: 1x time
    final roundScore = state.pointsEarnedInRound;
    final time = state.timeRemaining;

    // Apply clutch multiplier to remaining time
    final timeMultiplier = ClutchConfig.getMultiplier(time);

    final adjustedTime = (time * timeMultiplier).round();
    final newTime = adjustedTime + roundScore;

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
    final newTime = (state.timeRemaining - TimeConfig.wrongAnswerPenalty).clamp(0, 999);

    // Only clear current selection, keep banked words (committedWord) safe
    emit(state.copyWith(
      timeRemaining: newTime,
      selectedLetterIds: [], // Clear current drag selection
      // Note: committedWord is preserved - banked words are safe!
      lastAnswerCorrect: false,
      // Don't reset spaceUsageCount - banked spaces are still valid
      repeatUsageCount: 0, // Only reset repeat count for current selection
      isPureConnection: false, // Reset for next attempt
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
      letterRoundStartScore: 0,
      timeRemaining: GameConfig.startingTime,
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
      hintsRemaining: GameConfig.startingHints,
      clearHintWord: true,
      // Reset mystery orb state
      mysteryOrbs: [],
      consecutivePenalties: 0,
      scoreMultiplierActive: false,
      clearLastMysteryOutcome: true,
      clearPendingMysteryOrb: true,
      clearMysteryOrbDwellStartTime: true,
    ));
  }

  // ============================================
  // MYSTERY ORB METHODS
  // ============================================

  /// Determine mystery outcome using probability weights and pity system
  MysteryOutcome _determineMysteryOutcome() {
    // Pity system: after consecutive penalties, guarantee a reward
    if (state.consecutivePenalties >= MysteryOrbConfig.pityThreshold) {
      // Force a reward
      final rewards = [
        MysteryOutcome.timeBonus,
        MysteryOutcome.scoreMultiplier,
        MysteryOutcome.freeHint,
      ];
      final rewardWeights = [40, 15, 10]; // Same relative weights
      final totalWeight = rewardWeights.reduce((a, b) => a + b);
      var roll = _random.nextInt(totalWeight);

      for (int i = 0; i < rewards.length; i++) {
        roll -= rewardWeights[i];
        if (roll < 0) return rewards[i];
      }
      return MysteryOutcome.timeBonus;
    }

    // Progressive difficulty: early rounds favor rewards more
    // Base: 65/35 reward/penalty
    // Round 1-5: 75/25
    // Round 6-10: 70/30
    // Round 11+: 65/35
    int rewardBonus = 0;
    if (state.letterRound <= 5) {
      rewardBonus = 10; // +10% to rewards
    } else if (state.letterRound <= 10) {
      rewardBonus = 5; // +5% to rewards
    }

    // Calculate total weight and roll
    int totalWeight = 0;
    for (final entry in _mysteryOutcomeProbabilities.entries) {
      int weight = entry.value;
      // Apply reward bonus
      if (_isRewardOutcome(entry.key)) {
        weight = (weight * (100 + rewardBonus) ~/ 100);
      }
      totalWeight += weight;
    }

    var roll = _random.nextInt(totalWeight);

    for (final entry in _mysteryOutcomeProbabilities.entries) {
      int weight = entry.value;
      if (_isRewardOutcome(entry.key)) {
        weight = (weight * (100 + rewardBonus) ~/ 100);
      }
      roll -= weight;
      if (roll < 0) return entry.key;
    }

    return MysteryOutcome.timeBonus; // Fallback
  }

  /// Check if outcome is a reward (vs penalty)
  bool _isRewardOutcome(MysteryOutcome outcome) {
    return outcome == MysteryOutcome.timeBonus ||
        outcome == MysteryOutcome.scoreMultiplier ||
        outcome == MysteryOutcome.freeHint;
  }

  /// Scramble letter positions (keep same letters, different positions)
  List<LetterNode> _scrambleLetterPositions() {
    final positions = state.letters.map((l) => l.position).toList();
    positions.shuffle(_random);

    final scrambled = <LetterNode>[];
    for (int i = 0; i < state.letters.length; i++) {
      final original = state.letters[i];
      scrambled.add(LetterNode(
        id: original.id,
        letter: original.letter,
        points: original.points,
        position: positions[i],
      ));
    }
    return scrambled;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
