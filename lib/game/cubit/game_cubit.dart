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

  // Background time tracking - prevent cheating by backgrounding the app
  DateTime? _backgroundedAt;

  // Sticky/magnetic selection tracking
  int? _pendingLetterId;
  DateTime? _pendingLetterEnteredAt;
  Offset? _lastDragPosition;
  DateTime? _lastDragTime;

  // Hit detection config from constants
  static const Duration _dwellTime = Duration(milliseconds: HitDetectionConfig.dwellTimeMs);
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

  /// Check if there's saved game progress that can be resumed
  Future<bool> hasSavedProgress() async {
    return StorageService.instance.hasSavedProgress();
  }

  /// Load saved progress info (for UI display)
  Future<SavedGameProgress?> getSavedProgress() async {
    return StorageService.instance.loadGameProgress();
  }

  /// Resume from saved progress - starts at the saved letter round
  Future<void> resumeGame() async {
    final progress = await StorageService.instance.loadGameProgress();
    if (progress == null) {
      // No saved progress, start fresh
      startGame();
      return;
    }

    // Load saved stars (persisted across games)
    final savedStars = await StorageService.instance.loadStars();

    _initializeLetters();
    emit(state.copyWith(
      timeRemaining: progress.timeRemaining,
      score: progress.score,
      letterRound: progress.letterRound,
      letterRoundStartScore: progress.score, // Start tracking from current score
      completedLetters: progress.completedLetters,
      isPlaying: false,
      isWinner: false,
      phase: GamePhase.spinningWheel,
      clearCurrentLetter: true,
      category: '',
      currentCategories: [],
      categoryIndex: 0,
      clearLastAnswerCorrect: true,
      hintsRemaining: progress.hintsRemaining,
      clearHintWord: true,
      // Reset mystery orb state
      mysteryOrbs: [],
      consecutivePenalties: 0,
      scoreMultiplierActive: false,
      clearLastMysteryOutcome: true,
      clearPendingMysteryOrb: true,
      clearMysteryOrbDwellStartTime: true,
      // Star tracking - load balance, calculate threshold from current score
      stars: savedStars,
      starsEarnedThisGame: 0,
      lastStarThreshold: (progress.score ~/ StarConfig.pointsPerStar) * StarConfig.pointsPerStar,
      showStarEarnedAnimation: false,
    ));
  }

  /// Start Alpha Quest game - go to spinning wheel (fresh start)
  void startGame() async {
    // Clear any saved progress when starting fresh
    StorageService.instance.clearGameProgress();

    // Load saved stars (persisted across games)
    final savedStars = await StorageService.instance.loadStars();

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
      // Reset cheat code and hint tracking
      skipCheatUsedThisRound: false,
      clearUsedHintWords: true,
      // Star tracking - preserve balance, reset per-game tracking
      stars: savedStars,
      starsEarnedThisGame: 0,
      lastStarThreshold: 0,
      showStarEarnedAnimation: false,
    ));
  }

  /// Save game progress for later resumption
  Future<void> _saveProgress({
    required int letterRound,
    required List<String> completedLetters,
    required int score,
    required int timeRemaining,
    required int hintsRemaining,
  }) async {
    await StorageService.instance.saveGameProgress(
      letterRound: letterRound,
      completedLetters: completedLetters,
      score: score,
      timeRemaining: timeRemaining,
      hintsRemaining: hintsRemaining,
    );
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

    // Reset all drag/interaction state along with letters for clean start
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    _lastDragPosition = null;
    _lastDragTime = null;

    emit(state.copyWith(
      phase: GamePhase.playingRound,
      selectedLetterIds: [],
      committedWord: '',
      letters: result.letters,
      mysteryOrbs: result.mysteryOrbs, // Already active, part of the grid
      clearPendingMysteryOrb: true,
      clearMysteryOrbDwellStartTime: true,
      isDragging: false, // Ensure clean drag state for new category
      clearDragPosition: true,
      approachingLetterIds: [],
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
  /// Uses PATH-CLEARANCE OPTIMIZATION: random placement but pushes
  /// non-target letters away from paths between target word letters
  /// Mystery orbs REPLACE actual letters (prioritizing vowels) - like Scrabble blanks
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

    // Get target words for path clearance optimization
    final validWords = _dictionary.getWordsForCategoryAndLetter(category, letter);
    final targetWords = _getShortestTargetWords(validWords, 3);

    // All items to place (letters + mystery orb placeholders)
    final allItems = [...remainingLetters, ...lettersToReplace];

    // Generate positions with path clearance optimization
    final positions = _generatePositionsWithPathClearance(
      allItems,
      targetWords,
    );

    final letters = <LetterNode>[];
    final mysteryOrbs = <MysteryOrb>[];

    // Create letter nodes
    for (final letterChar in remainingLetters) {
      final points = LetterPoints.values[letterChar] ?? 1;
      final id = letterChar.codeUnitAt(0) - 'A'.codeUnitAt(0);

      letters.add(LetterNode(
        id: id,
        letter: letterChar,
        points: points,
        position: positions[letterChar] ?? const Offset(0.5, 0.5),
      ));
    }

    // Create mystery orbs
    for (int i = 0; i < lettersToReplace.length; i++) {
      final replacedLetter = lettersToReplace[i];
      mysteryOrbs.add(MysteryOrb(
        id: 100 + i,
        position: positions[replacedLetter] ?? const Offset(0.5, 0.5),
        isActive: true,
        replacedLetter: replacedLetter,
      ));
    }

    return (letters: letters, mysteryOrbs: mysteryOrbs);
  }

  /// Get shortest target words for path optimization
  List<String> _getShortestTargetWords(List<String> validWords, int count) {
    if (validWords.isEmpty) return [];
    final sorted = List<String>.from(validWords)
      ..sort((a, b) => a.replaceAll(' ', '').length.compareTo(b.replaceAll(' ', '').length));
    return sorted.take(count).toList();
  }

  /// Generate positions with path clearance - random but pushes letters away from target paths
  Map<String, Offset> _generatePositionsWithPathClearance(
    List<String> allItems,
    List<String> targetWords,
  ) {
    final totalItems = allItems.length;
    if (totalItems == 0) return {};

    // Layout bounds
    const paddingX = 0.08;
    const paddingY = 0.08;
    const maxY = 0.84;

    // Step 1: Generate initial random grid positions
    final cols = totalItems <= 9 ? 3 : (totalItems <= 16 ? 4 : (totalItems <= 25 ? 5 : 6));
    final rows = (totalItems / cols).ceil();
    final availableWidth = 1.0 - (paddingX * 2);
    final availableHeight = maxY - paddingY;
    final cellWidth = availableWidth / cols;
    final cellHeight = availableHeight / rows;
    final jitterX = cellWidth * 0.20;
    final jitterY = cellHeight * 0.20;

    final gridPositions = <Offset>[];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (gridPositions.length >= totalItems) break;
        final baseX = paddingX + (col + 0.5) * cellWidth;
        final baseY = paddingY + (row + 0.5) * cellHeight;
        final x = baseX + (_random.nextDouble() - 0.5) * 2 * jitterX;
        final y = baseY + (_random.nextDouble() - 0.5) * 2 * jitterY;
        gridPositions.add(Offset(
          x.clamp(paddingX, 1.0 - paddingX),
          y.clamp(paddingY, maxY),
        ));
      }
    }

    // Shuffle for random initial assignment
    gridPositions.shuffle(_random);

    // Step 2: Assign letters to positions randomly
    var positions = <String, Offset>{};
    for (int i = 0; i < allItems.length; i++) {
      positions[allItems[i]] = gridPositions[i];
    }

    // Step 3: If no target words, return random positions
    if (targetWords.isEmpty) return positions;

    // Step 4: Build path segments from target words
    final pathSegments = <(Offset, Offset, Set<String>)>[]; // (start, end, lettersInPath)
    for (final word in targetWords) {
      final letters = word.toUpperCase().replaceAll(' ', '').split('');
      final lettersInWord = letters.toSet();
      for (int i = 0; i < letters.length - 1; i++) {
        final startLetter = letters[i];
        final endLetter = letters[i + 1];
        final startPos = positions[startLetter];
        final endPos = positions[endLetter];
        if (startPos != null && endPos != null) {
          pathSegments.add((startPos, endPos, lettersInWord));
        }
      }
    }

    // Step 5: Iteratively push non-path letters away from corridors
    const iterations = 12;
    const corridorWidth = 0.08; // How wide the "clear zone" should be
    const pushStrength = 0.025;
    const minSpacing = 0.09; // Minimum distance between any two letters

    for (int iter = 0; iter < iterations; iter++) {
      final newPositions = <String, Offset>{};

      for (final entry in positions.entries) {
        final letter = entry.key;
        var pos = entry.value;
        var forceX = 0.0;
        var forceY = 0.0;

        // Check each path segment
        for (final segment in pathSegments) {
          final segStart = segment.$1;
          final segEnd = segment.$2;
          final lettersInPath = segment.$3;

          // Skip if this letter is part of this word's path
          if (lettersInPath.contains(letter)) continue;

          // Calculate distance to segment
          final dist = _pointToSegmentDistance(pos, segStart, segEnd);

          // If within corridor, push away
          if (dist < corridorWidth) {
            final pushAmount = pushStrength * (1.0 - dist / corridorWidth);
            final pushDir = _getPushDirection(pos, segStart, segEnd);
            forceX += pushDir.dx * pushAmount;
            forceY += pushDir.dy * pushAmount;
          }
        }

        // Also maintain minimum spacing between all letters
        for (final other in positions.entries) {
          if (other.key == letter) continue;
          final dist = _distance(pos, other.value);
          if (dist < minSpacing && dist > 0.001) {
            final pushAmount = pushStrength * (1.0 - dist / minSpacing);
            final dx = pos.dx - other.value.dx;
            final dy = pos.dy - other.value.dy;
            final norm = sqrt(dx * dx + dy * dy);
            if (norm > 0.001) {
              forceX += (dx / norm) * pushAmount;
              forceY += (dy / norm) * pushAmount;
            }
          }
        }

        // Apply forces
        final newX = (pos.dx + forceX).clamp(paddingX, 1.0 - paddingX);
        final newY = (pos.dy + forceY).clamp(paddingY, maxY);
        newPositions[letter] = Offset(newX, newY);
      }

      // Update path segments with new positions for next iteration
      positions = newPositions;
      pathSegments.clear();
      for (final word in targetWords) {
        final letters = word.toUpperCase().replaceAll(' ', '').split('');
        final lettersInWord = letters.toSet();
        for (int i = 0; i < letters.length - 1; i++) {
          final startLetter = letters[i];
          final endLetter = letters[i + 1];
          final startPos = positions[startLetter];
          final endPos = positions[endLetter];
          if (startPos != null && endPos != null) {
            pathSegments.add((startPos, endPos, lettersInWord));
          }
        }
      }
    }

    return positions;
  }

  /// Calculate distance from point to line segment
  double _pointToSegmentDistance(Offset point, Offset segStart, Offset segEnd) {
    final dx = segEnd.dx - segStart.dx;
    final dy = segEnd.dy - segStart.dy;
    final lengthSq = dx * dx + dy * dy;

    if (lengthSq < 0.0001) return _distance(point, segStart);

    var t = ((point.dx - segStart.dx) * dx + (point.dy - segStart.dy) * dy) / lengthSq;
    t = t.clamp(0.0, 1.0);

    final projX = segStart.dx + t * dx;
    final projY = segStart.dy + t * dy;
    return _distance(point, Offset(projX, projY));
  }

  /// Get direction to push a point away from a segment
  Offset _getPushDirection(Offset point, Offset segStart, Offset segEnd) {
    final dx = segEnd.dx - segStart.dx;
    final dy = segEnd.dy - segStart.dy;
    final lengthSq = dx * dx + dy * dy;

    if (lengthSq < 0.0001) {
      // Segment is a point, push directly away
      final away = Offset(point.dx - segStart.dx, point.dy - segStart.dy);
      final norm = sqrt(away.dx * away.dx + away.dy * away.dy);
      if (norm < 0.001) return const Offset(1, 0);
      return Offset(away.dx / norm, away.dy / norm);
    }

    // Find closest point on segment
    var t = ((point.dx - segStart.dx) * dx + (point.dy - segStart.dy) * dy) / lengthSq;
    t = t.clamp(0.0, 1.0);
    final closestX = segStart.dx + t * dx;
    final closestY = segStart.dy + t * dy;

    // Push perpendicular to segment (away from closest point)
    var pushX = point.dx - closestX;
    var pushY = point.dy - closestY;
    final norm = sqrt(pushX * pushX + pushY * pushY);

    if (norm < 0.001) {
      // Point is on the segment, push perpendicular
      pushX = -dy;
      pushY = dx;
      final perpNorm = sqrt(pushX * pushX + pushY * pushY);
      if (perpNorm > 0.001) {
        return Offset(pushX / perpNorm, pushY / perpNorm);
      }
      return const Offset(1, 0);
    }

    return Offset(pushX / norm, pushY / norm);
  }

  /// Euclidean distance between two points
  double _distance(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
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
          // Hit the same letter - just continue dragging, don't repeat
          // Double letters are only allowed via the x2 repeat button
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
      if (hit != null) {
        // No path validation during selection - players find out at GO time
        // This removes hints about whether they're on the right track
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

  /// Update drag position and check for new letter/orb hits
  /// ALL selections during drag require dwell time - no immediate selection
  /// This prevents accidental connections when dragging quickly
  void updateDrag(Offset relativePosition) {
    if (!state.isDragging) return;

    final now = DateTime.now();

    // Update tracking for next frame
    _lastDragPosition = relativePosition;
    _lastDragTime = now;

    // Check if we're over any letter or mystery orb (use outer radius for detection)
    final hit = _findSelectableAtPosition(relativePosition, _outerHitRadius);

    final lastSelectedId = state.selectedLetterIds.isNotEmpty
        ? state.selectedLetterIds.last
        : null;

    // If we're over a selectable item that's not already the last selected
    if (hit != null && hit.id != lastSelectedId) {
      // Check if this is the same item we were tracking
      if (_pendingLetterId == hit.id) {
        // Same item - check if dwell time has elapsed
        final elapsed = now.difference(_pendingLetterEnteredAt!);
        if (elapsed >= _dwellTime) {
          // Dwell time met - confirm selection
          _confirmSelection(hit.id, hit.letter, hit.isOrb, relativePosition, fromDrag: true);
        } else {
          // Still dwelling - show approaching state for visual feedback
          if (hit.isOrb) {
            emit(state.copyWith(
              currentDragPosition: relativePosition,
              approachingLetterIds: [],
              pendingMysteryOrbId: hit.id,
              mysteryOrbDwellStartTime: state.mysteryOrbDwellStartTime ?? now,
              clearPendingLetterId: true,
              clearLetterDwellStartTime: true,
            ));
          } else {
            emit(state.copyWith(
              currentDragPosition: relativePosition,
              approachingLetterIds: [hit.id],
              pendingLetterId: hit.id,
              letterDwellStartTime: state.letterDwellStartTime ?? now,
              clearPendingMysteryOrb: true,
              clearMysteryOrbDwellStartTime: true,
            ));
          }
        }
      } else {
        // New item - start tracking dwell time from scratch
        _pendingLetterId = hit.id;
        _pendingLetterEnteredAt = now;
        if (hit.isOrb) {
          emit(state.copyWith(
            currentDragPosition: relativePosition,
            approachingLetterIds: [],
            pendingMysteryOrbId: hit.id,
            mysteryOrbDwellStartTime: now,
            clearPendingLetterId: true,
            clearLetterDwellStartTime: true,
          ));
        } else {
          emit(state.copyWith(
            currentDragPosition: relativePosition,
            approachingLetterIds: [hit.id],
            pendingLetterId: hit.id,
            letterDwellStartTime: now,
            clearPendingMysteryOrb: true,
            clearMysteryOrbDwellStartTime: true,
          ));
        }
      }
      return;
    }

    // Outside all hit zones - reset pending state
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    emit(state.copyWith(
      currentDragPosition: relativePosition,
      approachingLetterIds: [],
      clearPendingMysteryOrb: true,
      clearMysteryOrbDwellStartTime: true,
      clearPendingLetterId: true,
      clearLetterDwellStartTime: true,
    ));
  }

  /// Confirm selection of a letter OR mystery orb
  /// No path validation during selection - players find out at GO time
  /// [fromDrag] indicates if this came from dragging (true) or tapping (false)
  /// Only dragging maintains pure connection status
  void _confirmSelection(int id, String letter, bool isOrb, Offset position, {bool fromDrag = false}) {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;

    // During drag, prevent selecting the same letter consecutively (no double letters)
    // Double letters are only allowed via tap or x2 button, not during drag
    if (fromDrag && state.selectedLetterIds.isNotEmpty && state.selectedLetterIds.last == id) {
      return; // Skip - this letter is already the last selected
    }

    // Add the item with clear feedback when connected
    AudioService.instance.play(GameSound.letterSelect);
    HapticService.instance.medium(); // Medium haptic for letter connection

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
            clearPendingLetterId: true,
            clearLetterDwellStartTime: true,
            lastMysteryOutcome: outcome,
            lastConnectedLetterId: id, // For connection flash animation
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
      clearPendingLetterId: true,
      clearLetterDwellStartTime: true,
      lastConnectedLetterId: id, // For connection flash animation
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
    // Don't allow consecutive duplicates via tap - use x2 button instead
    if (state.selectedLetterIds.isNotEmpty && state.selectedLetterIds.last == letterId) {
      return; // Skip - double letters only allowed via x2 repeat button
    }

    // Add letter to selection
    // Tapping letters breaks pure connection (only dragging maintains it)
    final newSelection = [...state.selectedLetterIds, letterId];
    emit(state.copyWith(
      selectedLetterIds: newSelection,
      isPureConnection: false, // Tapping breaks pure connection
    ));
  }

  void clearSelection() {
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    emit(state.copyWith(
      selectedLetterIds: [],
      committedWord: '', // Also clear committed word
      clearDragPosition: true,
      spaceUsageCount: 0, // Reset bonus counts
      repeatUsageCount: 0,
      isPureConnection: false, // Reset pure connection tracking
      showConnectionAnimation: false,
      clearPendingLetterId: true,
      clearLetterDwellStartTime: true,
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

  /// Skip category cheat - activated by shake pattern (right, right, left)
  /// Skips current category and adds 15 seconds. Can only be used once per letter round.
  /// Returns true if cheat was activated, false if already used or not in playing phase
  bool skipCategoryCheat() {
    // Only works during active gameplay
    if (state.phase != GamePhase.playingRound) return false;
    // Can only use once per letter round
    if (state.skipCheatUsedThisRound) return false;
    // Need a current letter/category to skip
    if (state.currentLetter == null) return false;

    // Play feedback
    AudioService.instance.play(GameSound.wordCorrect);
    HapticService.instance.success();

    final nextCategoryIndex = state.categoryIndex + 1;
    final timeBonus = 15;
    final newTime = (state.timeRemaining + timeBonus).clamp(0, 999);

    // Check if we completed all 5 categories for this letter
    if (nextCategoryIndex >= GameState.categoriesPerLetter) {
      // Letter complete! Move to celebration
      emit(state.copyWith(
        skipCheatUsedThisRound: true,
        timeRemaining: newTime,
      ));
      _completeLetterRound(state.score, state.completedWords);
    } else {
      // Move to next category
      final nextCategory = state.currentCategories[nextCategoryIndex];
      emit(state.copyWith(
        skipCheatUsedThisRound: true,
        timeRemaining: newTime,
        categoryIndex: nextCategoryIndex,
        category: nextCategory,
        selectedLetterIds: [],
        committedWord: '',
        clearLastAnswerCorrect: true,
        clearLastTimeBonus: true,
        phase: GamePhase.categoryReveal,
        spaceUsageCount: 0,
        repeatUsageCount: 0,
        showConnectionAnimation: false,
        isDragging: false,
        clearDragPosition: true,
        approachingLetterIds: [],
        clearHintWord: true,
      ));
    }

    return true;
  }

  // Hint configuration from constants
  static const int _minTimeForHint = TimeConfig.minTimeForHint;
  static const int _hintTimeCost = TimeConfig.hintTimeCost;

  /// Use a hint - animates letters in sequence for a valid word
  /// Earlier rounds get shorter words, later rounds allow varied lengths
  /// Returns true if hint was used, false if no hints remaining or not enough time
  bool useHint() {
    if (state.hintsRemaining <= 0) return false;
    if (state.currentLetter == null) return false;
    // Don't allow hints with less than 15 seconds remaining
    if (state.timeRemaining < _minTimeForHint) return false;

    // Get all valid words for this category/letter
    final allWords = _dictionary.getWordsForCategoryAndLetter(
      state.category,
      state.currentLetter!,
    );

    if (allWords.isEmpty) return false;

    // Determine max word length based on round (shorter hints early)
    final round = state.letterRound;
    final maxLength = HintConfig.getMaxHintLength(round);

    // Get words already shown as hints for this category
    final alreadyUsedHints = state.usedHintWords[state.category] ?? [];

    // Filter words by max length and exclude already-used hints
    var eligibleWords = allWords.where((w) {
      final letterCount = w.replaceAll(' ', '').length;
      final notUsed = !alreadyUsedHints.contains(w.toUpperCase());
      return letterCount <= maxLength && notUsed;
    }).toList();

    // If no words fit the length limit, fall back to shortest available (excluding used hints)
    if (eligibleWords.isEmpty) {
      // Filter out already-used hints first
      final unusedWords = allWords.where((w) => !alreadyUsedHints.contains(w.toUpperCase())).toList();
      if (unusedWords.isEmpty) return false; // All words already shown as hints

      // Sort by length and take the shortest ones
      final sorted = List<String>.from(unusedWords)
        ..sort((a, b) => a.replaceAll(' ', '').length.compareTo(b.replaceAll(' ', '').length));
      final shortestLength = sorted.first.replaceAll(' ', '').length;
      eligibleWords = sorted.where((w) => w.replaceAll(' ', '').length == shortestLength).toList();
    }

    // In early rounds, prefer the shortest from eligible words
    String hintWord;
    if (round <= HintConfig.preferShortestRoundThreshold) {
      // Sort by length and pick from shortest
      eligibleWords.sort((a, b) => a.replaceAll(' ', '').length.compareTo(b.replaceAll(' ', '').length));
      final shortestLength = eligibleWords.first.replaceAll(' ', '').length;
      final shortestWords = eligibleWords.where((w) => w.replaceAll(' ', '').length == shortestLength).toList();
      hintWord = shortestWords[_random.nextInt(shortestWords.length)];
    } else {
      // Later rounds: random from eligible
      hintWord = eligibleWords[_random.nextInt(eligibleWords.length)];
    }

    // Compute the sequence of letter node IDs
    final hintLetterIds = _computeHintLetterSequence(hintWord);
    if (hintLetterIds.isEmpty) return false;

    // Haptic feedback for hint
    HapticService.instance.medium();

    // Deduct 10 seconds for using a hint
    final newTime = state.timeRemaining - _hintTimeCost;

    // Track this hint word as used for this category
    final updatedUsedHints = Map<String, List<String>>.from(state.usedHintWords);
    final categoryHints = List<String>.from(updatedUsedHints[state.category] ?? []);
    categoryHints.add(hintWord.toUpperCase());
    updatedUsedHints[state.category] = categoryHints;

    emit(state.copyWith(
      hintsRemaining: state.hintsRemaining - 1,
      hintWord: hintWord,
      hintLetterIds: hintLetterIds,
      hintAnimationIndex: 0,
      timeRemaining: newTime,
      usedHintWords: updatedUsedHints,
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
        // Returns (word, isFuzzy) tuple
        final matchResult = _findMatchingWordWithFuzzyFlag(pattern, state.category, state.currentLetter!);
        if (matchResult != null) {
          _handleCorrectAnswer(matchResult.word, isFuzzyMatch: matchResult.isFuzzy);
        } else {
          _handleWrongAnswer();
        }
      } else {
        // No wildcards - try exact match first, then fuzzy match for minor typos
        final isValid = _dictionary.isValidWord(
          pattern,
          state.category,
          state.currentLetter!,
        );

        if (isValid) {
          _handleCorrectAnswer(pattern, isFuzzyMatch: false);
        } else {
          // Try fuzzy matching for minor spelling mistakes
          // (one letter off, transposed letters, etc.)
          final fuzzyMatch = _findFuzzyMatch(pattern, state.category, state.currentLetter!);
          if (fuzzyMatch != null) {
            // Fuzzy match - no points awarded but still passes
            _handleCorrectAnswer(fuzzyMatch, isFuzzyMatch: true);
          } else {
            _handleWrongAnswer();
          }
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
  /// Also supports fuzzy matching for minor typos in non-wildcard letters
  /// Returns the matched word and whether it was a fuzzy match, or null if no match
  ({String word, bool isFuzzy})? _findMatchingWordWithFuzzyFlag(String pattern, String category, String startLetter) {
    final validWords = _dictionary.getWordsForCategoryAndLetter(category, startLetter);
    final upperPattern = pattern.toUpperCase();
    final patternNoSpaces = upperPattern.replaceAll(' ', '');

    // First try exact pattern match (wildcards match any letter)
    for (final word in validWords) {
      final upperWord = word.toUpperCase().replaceAll(' ', '');

      if (_matchesPattern(upperWord, patternNoSpaces)) {
        return (word: word, isFuzzy: false); // Exact match
      }
    }

    // No exact pattern match - try fuzzy matching
    // Replace wildcards with the actual letters from potential matches and check edit distance
    String? bestMatch;
    int bestDistance = 999;

    for (final word in validWords) {
      final upperWord = word.toUpperCase().replaceAll(' ', '');

      // Quick reject: length must be close
      final lenDiff = (patternNoSpaces.length - upperWord.length).abs();
      if (lenDiff > 2) continue;

      // Create a version of the pattern with wildcards filled in from the word
      // Then check edit distance of non-wildcard characters
      if (_matchesPatternFuzzy(upperWord, patternNoSpaces)) {
        // Calculate how different the non-wildcard parts are
        final distance = _patternEditDistance(upperWord, patternNoSpaces);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestMatch = word;
        }
      }
    }

    if (bestMatch != null) {
      return (word: bestMatch, isFuzzy: true); // Fuzzy match
    }
    return null;
  }

  /// Check if word could match pattern with fuzzy tolerance for non-wildcard chars
  /// Pattern may contain '*' wildcards
  bool _matchesPatternFuzzy(String word, String pattern) {
    // Same length or within 1-2 characters (for fuzzy)
    final lenDiff = (word.length - pattern.length).abs();
    if (lenDiff > 2) return false;

    // For same-length words, count mismatches (excluding wildcards)
    if (word.length == pattern.length) {
      int mismatches = 0;
      for (int i = 0; i < pattern.length; i++) {
        if (pattern[i] == GameState.wildcardChar) continue;
        if (pattern[i] != word[i]) mismatches++;
      }
      // Allow up to 1-2 mismatches based on word length
      final maxMismatches = word.length >= 8 ? 2 : 1;
      return mismatches <= maxMismatches;
    }

    // For different lengths, use a more lenient check
    // The pattern edit distance function will handle this
    return true;
  }

  /// Calculate edit distance considering wildcards in pattern
  /// Wildcards are "free" - they don't count as edits
  int _patternEditDistance(String word, String pattern) {
    // For same-length words with wildcards, count non-matching non-wildcard positions
    if (word.length == pattern.length) {
      int distance = 0;
      for (int i = 0; i < pattern.length; i++) {
        if (pattern[i] == GameState.wildcardChar) continue;
        if (pattern[i] != word[i]) distance++;
      }
      return distance;
    }

    // For different lengths, use regular Levenshtein but treat wildcards as matching
    // This is a simplified approach - replace wildcards with the corresponding letter
    // from the word if lengths match up
    return _levenshteinDistance(word, pattern.replaceAll(GameState.wildcardChar, '?'));
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

  /// Calculate Levenshtein (edit) distance between two strings
  /// Counts minimum number of single-character edits (insertions, deletions, substitutions)
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    // Use two-row optimization for space efficiency
    List<int> previousRow = List.generate(s2.length + 1, (i) => i);
    List<int> currentRow = List.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      currentRow[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final insertCost = currentRow[j] + 1;
        final deleteCost = previousRow[j + 1] + 1;
        final substituteCost = previousRow[j] + (s1[i] == s2[j] ? 0 : 1);

        currentRow[j + 1] = min(min(insertCost, deleteCost), substituteCost);
      }

      // Swap rows
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[s2.length];
  }

  /// Check if two strings are within acceptable edit distance for fuzzy matching
  /// Shorter words (≤5 chars): allow 1 edit
  /// Longer words (>5 chars): allow 1-2 edits depending on length
  bool _isWithinFuzzyDistance(String input, String target) {
    final inputLen = input.length;
    final targetLen = target.length;

    // Quick reject: if length difference is too large, no point calculating
    final lenDiff = (inputLen - targetLen).abs();
    if (lenDiff > 2) return false;

    // For very short words (3-4 chars), only allow 1 edit
    // For medium words (5-7 chars), allow 1 edit
    // For longer words (8+ chars), allow up to 2 edits
    final maxDistance = targetLen >= 8 ? 2 : 1;

    // Also require length difference to be small
    if (lenDiff > maxDistance) return false;

    final distance = _levenshteinDistance(input, target);
    return distance <= maxDistance;
  }

  /// Find a fuzzy match for the input word in the valid words list
  /// Returns the matched valid word if found within acceptable edit distance, null otherwise
  String? _findFuzzyMatch(String input, String category, String startLetter) {
    final validWords = _dictionary.getWordsForCategoryAndLetter(category, startLetter);
    final upperInput = input.toUpperCase().replaceAll(' ', '');

    // First try exact match
    for (final word in validWords) {
      final upperWord = word.toUpperCase().replaceAll(' ', '');
      if (upperWord == upperInput) {
        return word; // Exact match
      }
    }

    // No exact match - try fuzzy matching
    // Find the best match (lowest edit distance) that's still acceptable
    String? bestMatch;
    int bestDistance = 999;

    for (final word in validWords) {
      final upperWord = word.toUpperCase().replaceAll(' ', '');

      // Quick check: length must be close enough
      final lenDiff = (upperInput.length - upperWord.length).abs();
      if (lenDiff > 2) continue;

      if (_isWithinFuzzyDistance(upperInput, upperWord)) {
        final distance = _levenshteinDistance(upperInput, upperWord);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestMatch = word;
        }
      }
    }

    return bestMatch;
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
  /// [isFuzzyMatch] - if true, no points are awarded (spelling mistake tolerance)
  void _handleCorrectAnswer(String word, {bool isFuzzyMatch = false}) {
    // Audio and haptic feedback for correct answer
    AudioService.instance.play(GameSound.wordCorrect);
    HapticService.instance.success();

    // No points for fuzzy matches (spelling mistakes)
    int wordScore = 0;
    if (!isFuzzyMatch) {
      wordScore = _calculateWordScore(word);

      // Apply score multiplier if active (from mystery orb)
      if (state.scoreMultiplierActive) {
        wordScore = (wordScore * ScoringConfig.mysteryScoreMultiplier).round();
      }
    }

    final newScore = state.score + wordScore;
    final newWords = [...state.completedWords, word];
    final nextCategoryIndex = state.categoryIndex + 1;

    // Check if player earned any stars (every 300 points)
    _checkAndAwardStars(newScore);

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
          isDragging: false, // Reset drag state for clean transition
          clearDragPosition: true,
          approachingLetterIds: [],
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

    // Note: Progress is saved in continueToNextRound() after time bonus is calculated

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
    // Letter completion bonus for completing all 5 categories
    final newTime = adjustedTime + roundScore + TimeConfig.letterCompletionBonus;

    final nextRound = state.letterRound + 1;

    // Save progress with the actual calculated time for next round
    _saveProgress(
      letterRound: nextRound,
      completedLetters: state.completedLetters,
      score: state.score,
      timeRemaining: newTime,
      hintsRemaining: state.hintsRemaining,
    );

    // Move to next letter round - timer stays paused until wheel lands
    emit(state.copyWith(
      letterRound: nextRound,
      timeRemaining: newTime,
      clearLastAnswerCorrect: true,
      phase: GamePhase.spinningWheel,
      clearCurrentLetter: true,
      currentCategories: [],
      categoryIndex: 0,
      isPlaying: false, // Timer paused until wheel lands
      skipCheatUsedThisRound: false, // Reset cheat for new letter round
      clearUsedHintWords: true, // Reset hint tracking for new letter round
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

    // Clear saved progress - game is over
    StorageService.instance.clearGameProgress();

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
  void resetGame() async {
    _timer?.cancel();

    // Load saved stars (persisted across games)
    final savedStars = await StorageService.instance.loadStars();

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
      // Reset cheat code and hint tracking
      skipCheatUsedThisRound: false,
      clearUsedHintWords: true,
      // Star tracking - preserve balance, reset per-game tracking
      stars: savedStars,
      starsEarnedThisGame: 0,
      lastStarThreshold: 0,
      showStarEarnedAnimation: false,
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

  // ============================================
  // STAR CURRENCY METHODS
  // ============================================

  /// Check if player earned a star (every 300 points)
  void _checkAndAwardStars(int newScore) {
    final threshold = StarConfig.pointsPerStar;
    final previousThreshold = state.lastStarThreshold;

    // Calculate how many thresholds we've crossed
    final newThreshold = (newScore ~/ threshold) * threshold;

    if (newThreshold > previousThreshold) {
      // Crossed a new threshold - award star(s)
      final starsEarned = (newThreshold - previousThreshold) ~/ threshold;

      // Play star earned sound and haptic
      AudioService.instance.play(GameSound.mysteryReward); // Reuse reward sound
      HapticService.instance.success();

      emit(state.copyWith(
        stars: state.stars + starsEarned,
        starsEarnedThisGame: state.starsEarnedThisGame + starsEarned,
        lastStarThreshold: newThreshold,
        showStarEarnedAnimation: true,
      ));

      // Clear animation flag after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (isClosed) return;
        emit(state.copyWith(showStarEarnedAnimation: false));
      });

      // Save updated star balance
      _saveStars();
    }
  }

  /// Skip current category using 1 star (no cheat code needed)
  /// Returns true if skip was successful, false if not enough stars
  bool skipCategoryWithStar() {
    // Only works during active gameplay
    if (state.phase != GamePhase.playingRound) return false;
    // Need at least 1 star
    if (state.stars < StarConfig.skipCategoryCost) return false;
    // Need a current letter/category to skip
    if (state.currentLetter == null) return false;

    // Play feedback
    AudioService.instance.play(GameSound.wordCorrect);
    HapticService.instance.success();

    final nextCategoryIndex = state.categoryIndex + 1;

    // Check if we completed all 5 categories for this letter
    if (nextCategoryIndex >= GameState.categoriesPerLetter) {
      // Letter complete! Move to celebration
      emit(state.copyWith(
        stars: state.stars - StarConfig.skipCategoryCost,
      ));
      _saveStars();
      _completeLetterRound(state.score, state.completedWords);
    } else {
      // Move to next category
      final nextCategory = state.currentCategories[nextCategoryIndex];
      emit(state.copyWith(
        stars: state.stars - StarConfig.skipCategoryCost,
        categoryIndex: nextCategoryIndex,
        category: nextCategory,
        selectedLetterIds: [],
        committedWord: '',
        clearLastAnswerCorrect: true,
        clearLastTimeBonus: true,
        phase: GamePhase.categoryReveal,
        spaceUsageCount: 0,
        repeatUsageCount: 0,
        showConnectionAnimation: false,
        isDragging: false,
        clearDragPosition: true,
        approachingLetterIds: [],
        clearHintWord: true,
      ));
      _saveStars();
    }

    return true;
  }

  /// Continue game after time runs out using 3 stars
  /// Returns true if continue was successful, false if not enough stars
  bool continueWithStars() {
    // Only works during game over phase
    if (state.phase != GamePhase.gameOver) return false;
    // Can only continue if it was a loss (not a win)
    if (state.isWinner) return false;
    // Need at least 3 stars
    if (state.stars < StarConfig.continueCost) return false;

    // Play feedback
    AudioService.instance.play(GameSound.roundComplete);
    HapticService.instance.success();

    // Deduct stars and give 60 seconds to continue from same round
    final continueTime = 60;

    emit(state.copyWith(
      stars: state.stars - StarConfig.continueCost,
      timeRemaining: continueTime,
      phase: GamePhase.playingRound,
      isPlaying: true,
      clearLastAnswerCorrect: true,
    ));

    _saveStars();
    _startTimer();

    return true;
  }

  /// Load saved stars from storage
  Future<void> loadSavedStars() async {
    final savedStars = await StorageService.instance.loadStars();
    emit(state.copyWith(stars: savedStars));
  }

  /// Save current star balance to storage
  Future<void> _saveStars() async {
    await StorageService.instance.saveStars(state.stars);
  }

  // ============================================
  // APP LIFECYCLE METHODS (background time tracking)
  // ============================================

  /// Called when app goes to background
  /// Stores the current timestamp and pauses the timer
  void onAppPaused() {
    if (!state.isPlaying) return; // Only track if actively playing

    _backgroundedAt = DateTime.now();
    _timer?.cancel();
  }

  /// Called when app returns to foreground
  /// Calculates elapsed wall-clock time and deducts from timeRemaining
  void onAppResumed() {
    if (_backgroundedAt == null) return; // Wasn't backgrounded while playing
    if (state.phase == GamePhase.notStarted ||
        state.phase == GamePhase.gameOver ||
        state.phase == GamePhase.letterComplete) {
      // Don't deduct time during these phases
      _backgroundedAt = null;
      return;
    }

    final now = DateTime.now();
    final elapsedSeconds = now.difference(_backgroundedAt!).inSeconds;
    _backgroundedAt = null;

    // Deduct elapsed time from remaining time
    final newTime = (state.timeRemaining - elapsedSeconds).clamp(0, 999);

    if (newTime <= 0) {
      // Time ran out while backgrounded
      _endGame(isWinner: false);
    } else {
      emit(state.copyWith(timeRemaining: newTime));
      // Restart the timer
      if (state.isPlaying) {
        _startTimer();
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
