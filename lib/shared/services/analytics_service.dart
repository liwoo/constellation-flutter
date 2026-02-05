import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics service for tracking key game metrics via Firebase Analytics
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  /// Initialize the analytics service
  Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _initialized = true;
      debugPrint('AnalyticsService: Initialized');
    } catch (e) {
      debugPrint('AnalyticsService: Failed to initialize - $e');
      _initialized = false;
    }
  }

  /// Check if analytics is ready
  bool get isInitialized => _initialized;

  /// Get the analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer {
    if (_analytics == null) return null;
    return FirebaseAnalyticsObserver(analytics: _analytics!);
  }

  // ============================================================
  // SESSION EVENTS
  // ============================================================

  /// User started a new game
  Future<void> logGameStart({required bool isNewGame}) async {
    await _logEvent('game_start', {
      'is_new_game': isNewGame,
      'start_type': isNewGame ? 'new' : 'resume',
    });
  }

  /// User completed a game (win or lose)
  Future<void> logGameComplete({
    required bool isWinner,
    required int finalScore,
    required int lettersCompleted,
    required int totalTimePlayedSeconds,
    required int starsEarned,
  }) async {
    await _logEvent('game_complete', {
      'is_winner': isWinner,
      'outcome': isWinner ? 'win' : 'lose',
      'final_score': finalScore,
      'letters_completed': lettersCompleted,
      'total_time_played': totalTimePlayedSeconds,
      'stars_earned': starsEarned,
    });

    // Also log as a purchase/achievement event for easier funnel analysis
    if (isWinner) {
      await _logEvent('game_won', {
        'score': finalScore,
        'stars_earned': starsEarned,
      });
    }
  }

  /// User abandoned a game (quit without completing)
  Future<void> logGameAbandon({
    required int letterRound,
    required int score,
    required int timeRemaining,
  }) async {
    await _logEvent('game_abandon', {
      'letter_round': letterRound,
      'score': score,
      'time_remaining': timeRemaining,
    });
  }

  // ============================================================
  // ROUND PROGRESS EVENTS
  // ============================================================

  /// User started a letter round
  Future<void> logLetterStarted({
    required String letter,
    required int letterRound,
    required int timeRemaining,
    required int currentScore,
  }) async {
    await _logEvent('letter_started', {
      'letter': letter,
      'letter_round': letterRound,
      'time_remaining': timeRemaining,
      'score': currentScore,
    });
  }

  /// User completed a letter round
  Future<void> logLetterCompleted({
    required String letter,
    required int letterRound,
    required int pointsEarned,
    required int timeRemaining,
    required int totalScore,
  }) async {
    await _logEvent('letter_completed', {
      'letter': letter,
      'letter_round': letterRound,
      'points_earned': pointsEarned,
      'time_remaining': timeRemaining,
      'total_score': totalScore,
    });
  }

  /// User completed a category within a letter round
  Future<void> logCategoryCompleted({
    required String category,
    required String letter,
    required int categoryIndex,
    required String word,
    required int pointsEarned,
  }) async {
    await _logEvent('category_completed', {
      'category': category,
      'letter': letter,
      'category_index': categoryIndex,
      'word': word,
      'points_earned': pointsEarned,
    });
  }

  // ============================================================
  // USER ACTION EVENTS
  // ============================================================

  /// User submitted a word
  Future<void> logWordSubmitted({
    required bool isCorrect,
    required String word,
    required String category,
    required int wordLength,
    required bool usedSpace,
    required bool usedRepeat,
    required bool usedMysteryOrb,
    required bool isPureConnection,
  }) async {
    await _logEvent('word_submitted', {
      'is_correct': isCorrect,
      'word': word,
      'category': category,
      'word_length': wordLength,
      'used_space': usedSpace,
      'used_repeat': usedRepeat,
      'used_mystery_orb': usedMysteryOrb,
      'is_pure_connection': isPureConnection,
    });
  }

  /// User used a hint
  Future<void> logHintUsed({
    required String hintWord,
    required int hintsRemaining,
    required String category,
    required int letterRound,
  }) async {
    await _logEvent('hint_used', {
      'hint_word': hintWord,
      'hints_remaining': hintsRemaining,
      'category': category,
      'letter_round': letterRound,
    });
  }

  /// User used skip (star cost)
  Future<void> logSkipUsed({
    required String category,
    required int starCost,
    required int starsRemaining,
    required int letterRound,
  }) async {
    await _logEvent('skip_used', {
      'category': category,
      'star_cost': starCost,
      'stars_remaining': starsRemaining,
      'letter_round': letterRound,
    });
  }

  /// User used continue (star cost after game over)
  Future<void> logContinueUsed({
    required int starCost,
    required int starsRemaining,
    required int letterRound,
    required int score,
  }) async {
    await _logEvent('continue_used', {
      'star_cost': starCost,
      'stars_remaining': starsRemaining,
      'letter_round': letterRound,
      'score': score,
    });
  }

  /// User used space button (bonus action)
  Future<void> logSpaceUsed({required int usageCount}) async {
    await _logEvent('bonus_space_used', {
      'usage_count': usageCount,
    });
  }

  /// User used repeat/x2 button (bonus action)
  Future<void> logRepeatUsed({required int usageCount}) async {
    await _logEvent('bonus_repeat_used', {
      'usage_count': usageCount,
    });
  }

  /// User activated a mystery orb
  Future<void> logMysteryOrbActivated({
    required String outcome,
    required bool isReward,
    required int letterRound,
  }) async {
    await _logEvent('mystery_orb_activated', {
      'outcome': outcome,
      'is_reward': isReward,
      'letter_round': letterRound,
    });
  }

  /// User achieved a pure connection (word built in single drag)
  Future<void> logPureConnection({
    required String word,
    required int wordLength,
    required int bonusTime,
  }) async {
    await _logEvent('pure_connection', {
      'word': word,
      'word_length': wordLength,
      'bonus_time': bonusTime,
    });
  }

  // ============================================================
  // MILESTONE EVENTS
  // ============================================================

  /// User earned a star
  Future<void> logStarEarned({
    required int totalStars,
    required int scoreThreshold,
  }) async {
    await _logEvent('star_earned', {
      'total_stars': totalStars,
      'score_threshold': scoreThreshold,
    });
  }

  /// User reached a score milestone
  Future<void> logScoreMilestone({
    required int milestone,
    required int letterRound,
  }) async {
    await _logEvent('score_milestone', {
      'milestone': milestone,
      'letter_round': letterRound,
    });
  }

  /// User reached the final round
  Future<void> logFinalRoundReached({
    required int score,
    required int timeRemaining,
    required int starsEarned,
  }) async {
    await _logEvent('final_round_reached', {
      'score': score,
      'time_remaining': timeRemaining,
      'stars_earned': starsEarned,
    });
  }

  // ============================================================
  // ENGAGEMENT EVENTS
  // ============================================================

  /// User viewed a specific screen
  Future<void> logScreenView({required String screenName}) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('AnalyticsService: Failed to log screen view - $e');
    }
  }

  /// User used the shake cheat
  Future<void> logCheatUsed({
    required String cheatType,
    required int letterRound,
  }) async {
    await _logEvent('cheat_used', {
      'cheat_type': cheatType,
      'letter_round': letterRound,
    });
  }

  /// Track time spent in a session
  Future<void> logSessionDuration({
    required int durationSeconds,
    required int roundsPlayed,
  }) async {
    await _logEvent('session_duration', {
      'duration_seconds': durationSeconds,
      'rounds_played': roundsPlayed,
    });
  }

  // ============================================================
  // USER PROPERTIES
  // ============================================================

  /// Set user property for high score
  Future<void> setHighScore(int score) async {
    await _setUserProperty('high_score', score.toString());
  }

  /// Set user property for total games played
  Future<void> setTotalGamesPlayed(int count) async {
    await _setUserProperty('total_games_played', count.toString());
  }

  /// Set user property for total wins
  Future<void> setTotalWins(int count) async {
    await _setUserProperty('total_wins', count.toString());
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  Future<void> _logEvent(String name, Map<String, Object>? parameters) async {
    if (_analytics == null) {
      debugPrint('AnalyticsService: Not initialized, skipping event: $name');
      return;
    }

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('AnalyticsService: Logged event: $name');
    } catch (e) {
      debugPrint('AnalyticsService: Failed to log event $name - $e');
    }
  }

  Future<void> _setUserProperty(String name, String value) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('AnalyticsService: Failed to set user property $name - $e');
    }
  }
}
