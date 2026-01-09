import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';

part 'alpha_quest_state.dart';

/// Cubit for managing Alpha Quest game mode
/// Players complete all 26 letters of the alphabet
class AlphaQuestCubit extends Cubit<AlphaQuestState> {
  AlphaQuestCubit() : super(const AlphaQuestState());

  Timer? _timer;
  final _dictionary = CategoryDictionary.instance;
  final _random = Random();

  // Letter point values (Scrabble-style)
  static const Map<String, int> _letterPoints = {
    'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4, 'G': 2, 'H': 4,
    'I': 1, 'J': 8, 'K': 5, 'L': 1, 'M': 3, 'N': 1, 'O': 1, 'P': 3,
    'Q': 10, 'R': 1, 'S': 1, 'T': 1, 'U': 1, 'V': 4, 'W': 4, 'X': 8,
    'Y': 4, 'Z': 10,
  };

  /// Start a new game
  void startGame() {
    emit(state.copyWith(
      timeRemaining: 120,
      score: 0,
      currentRound: 1,
      completedLetters: [],
      isPlaying: true,
      isGameOver: false,
      isWinner: false,
      currentLetter: null,
      currentCategory: null,
    ));
    _startTimer();
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

  /// Select a letter (after spinning wheel)
  void selectLetter(String letter) {
    final upperLetter = letter.toUpperCase();

    // Get a random category that has words for this letter
    final category = _getRandomCategoryForLetter(upperLetter);

    emit(state.copyWith(
      currentLetter: upperLetter,
      currentCategory: category,
      lastAnswerCorrect: null,
    ));
  }

  /// Set the category manually (for testing)
  void setCategory(String category) {
    emit(state.copyWith(currentCategory: category.toUpperCase()));
  }

  /// Get a random category that has words for the letter
  String? _getRandomCategoryForLetter(String letter) {
    final validCategories = CategoryDictionary.categories.where((cat) {
      return _dictionary.categoryHasWordsForLetter(cat, letter);
    }).toList();

    if (validCategories.isEmpty) return null;
    return validCategories[_random.nextInt(validCategories.length)];
  }

  /// Submit a word answer
  void submitWord(String word) {
    if (state.currentLetter == null || state.currentCategory == null) return;

    final isValid = _dictionary.isValidWord(
      word,
      state.currentCategory!,
      state.currentLetter!,
    );

    if (isValid) {
      _handleCorrectAnswer(word);
    } else {
      _handleWrongAnswer();
    }
  }

  /// Handle correct answer
  void _handleCorrectAnswer(String word) {
    final wordScore = calculateWordScore(word);
    final newCompletedLetters = [...state.completedLetters, state.currentLetter!];
    final newScore = state.score + wordScore;

    // Check if all letters completed
    final isWinner = newCompletedLetters.length >= 26;

    if (isWinner) {
      _endGame(isWinner: true, finalScore: newScore);
    } else {
      // Prepare for next round
      final nextRound = state.currentRound + 1;
      // Time formula: previous time - 15 + points earned
      final newTime = (state.timeRemaining - 15 + wordScore).clamp(0, 999);

      emit(state.copyWith(
        score: newScore,
        completedLetters: newCompletedLetters,
        currentRound: nextRound,
        timeRemaining: newTime,
        currentLetter: null,
        currentCategory: null,
        lastAnswerCorrect: true,
      ));
    }
  }

  /// Handle wrong answer - change category
  void _handleWrongAnswer() {
    // Get a different category for the same letter
    final currentCat = state.currentCategory;
    String? newCategory;

    final validCategories = CategoryDictionary.categories.where((cat) {
      return cat != currentCat &&
          _dictionary.categoryHasWordsForLetter(cat, state.currentLetter!);
    }).toList();

    if (validCategories.isNotEmpty) {
      newCategory = validCategories[_random.nextInt(validCategories.length)];
    } else {
      // No other category, keep the same one
      newCategory = currentCat;
    }

    // Deduct time penalty for wrong answer
    final newTime = (state.timeRemaining - 5).clamp(0, 999);

    emit(state.copyWith(
      currentCategory: newCategory,
      timeRemaining: newTime,
      lastAnswerCorrect: false,
    ));

    if (newTime <= 0) {
      _endGame(isWinner: false);
    }
  }

  /// Complete round with specific points (for testing)
  void completeRoundWithPoints(int points) {
    final newTime = (state.timeRemaining - 15 + points).clamp(0, 999);
    emit(state.copyWith(
      timeRemaining: newTime,
      currentRound: state.currentRound + 1,
    ));
  }

  /// Mark a letter as completed (for testing win condition)
  void markLetterCompleted(String letter) {
    if (!state.completedLetters.contains(letter.toUpperCase())) {
      final newCompleted = [...state.completedLetters, letter.toUpperCase()];
      final isWinner = newCompleted.length >= 26;
      emit(state.copyWith(
        completedLetters: newCompleted,
        isWinner: isWinner,
      ));
    }
  }

  /// Set time remaining (for testing)
  void setTimeRemaining(int time) {
    emit(state.copyWith(timeRemaining: time));
    if (time <= 0) {
      _endGame(isWinner: false);
    }
  }

  /// Calculate score for a word
  int calculateWordScore(String word) {
    final upperWord = word.toUpperCase();
    int score = 0;

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

  /// Get a random letter that hasn't been completed yet
  String? getNextRandomLetter() {
    final remainingLetters = <String>[];
    for (var i = 0; i < 26; i++) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
      if (!state.completedLetters.contains(letter)) {
        remainingLetters.add(letter);
      }
    }

    if (remainingLetters.isEmpty) return null;
    return remainingLetters[_random.nextInt(remainingLetters.length)];
  }

  /// End the game
  void _endGame({required bool isWinner, int? finalScore}) {
    _timer?.cancel();
    emit(state.copyWith(
      isPlaying: false,
      isGameOver: true,
      isWinner: isWinner,
      score: finalScore ?? state.score,
    ));
  }

  /// Pause the game
  void pauseGame() {
    _timer?.cancel();
    emit(state.copyWith(isPlaying: false));
  }

  /// Resume the game
  void resumeGame() {
    if (!state.isGameOver) {
      emit(state.copyWith(isPlaying: true));
      _startTimer();
    }
  }

  /// Reset the game
  void resetGame() {
    _timer?.cancel();
    emit(const AlphaQuestState());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
