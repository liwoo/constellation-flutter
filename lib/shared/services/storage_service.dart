import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/shared/models/models.dart';

/// Represents saved game progress for resuming
class SavedGameProgress {
  final int letterRound;
  final List<String> completedLetters;
  final int score;
  final int timeRemaining;
  final int hintsRemaining;
  final DateTime savedAt;

  const SavedGameProgress({
    required this.letterRound,
    required this.completedLetters,
    required this.score,
    required this.timeRemaining,
    required this.hintsRemaining,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'letterRound': letterRound,
        'completedLetters': completedLetters,
        'score': score,
        'timeRemaining': timeRemaining,
        'hintsRemaining': hintsRemaining,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedGameProgress.fromJson(Map<String, dynamic> json) {
    return SavedGameProgress(
      letterRound: json['letterRound'] as int,
      completedLetters: List<String>.from(json['completedLetters'] as List),
      score: json['score'] as int,
      timeRemaining: json['timeRemaining'] as int,
      hintsRemaining: json['hintsRemaining'] as int,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

/// Service for persisting game data locally
class StorageService {
  StorageService._();

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  SharedPreferences? _prefs;

  static const String _sessionsKey = 'game_sessions';
  static const String _highScoreKey = 'high_score';
  static const String _totalGamesKey = 'total_games';
  static const String _totalWinsKey = 'total_wins';
  static const String _savedProgressKey = 'saved_game_progress';
  static const String _starsKey = 'star_balance';

  /// Initialize the storage service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save a completed game session
  Future<void> saveGameSession(GameSession session) async {
    await init();

    // Get existing sessions
    final sessions = await getGameSessions();
    sessions.add(session);

    // Keep only the last 50 sessions
    if (sessions.length > 50) {
      sessions.removeRange(0, sessions.length - 50);
    }

    // Save sessions list
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await _prefs!.setString(_sessionsKey, jsonEncode(jsonList));

    // Update high score if needed
    final currentHighScore = await getHighScore();
    if (session.score > currentHighScore) {
      await _prefs!.setInt(_highScoreKey, session.score);
    }

    // Update stats
    final totalGames = await getTotalGames();
    await _prefs!.setInt(_totalGamesKey, totalGames + 1);

    if (session.isWinner) {
      final totalWins = await getTotalWins();
      await _prefs!.setInt(_totalWinsKey, totalWins + 1);
    }
  }

  /// Get all stored game sessions
  Future<List<GameSession>> getGameSessions() async {
    await init();

    final jsonString = _prefs!.getString(_sessionsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => GameSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get the top N high scores
  Future<List<GameSession>> getTopScores({int limit = 10}) async {
    final sessions = await getGameSessions();
    sessions.sort((a, b) => b.score.compareTo(a.score));
    return sessions.take(limit).toList();
  }

  /// Get the all-time high score
  Future<int> getHighScore() async {
    await init();
    return _prefs!.getInt(_highScoreKey) ?? 0;
  }

  /// Get total number of games played
  Future<int> getTotalGames() async {
    await init();
    return _prefs!.getInt(_totalGamesKey) ?? 0;
  }

  /// Get total number of wins (completed all 25 letters)
  Future<int> getTotalWins() async {
    await init();
    return _prefs!.getInt(_totalWinsKey) ?? 0;
  }

  /// Get recent sessions (last N games)
  Future<List<GameSession>> getRecentSessions({int limit = 5}) async {
    final sessions = await getGameSessions();
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions.take(limit).toList();
  }

  /// Clear all stored data (for testing/reset)
  Future<void> clearAll() async {
    await init();
    await _prefs!.remove(_sessionsKey);
    await _prefs!.remove(_highScoreKey);
    await _prefs!.remove(_totalGamesKey);
    await _prefs!.remove(_totalWinsKey);
    await _prefs!.remove(_savedProgressKey);
  }

  // ============================================
  // GAME PROGRESS PERSISTENCE (Resume Feature)
  // ============================================

  /// Save current game progress for later resumption
  Future<void> saveGameProgress({
    required int letterRound,
    required List<String> completedLetters,
    required int score,
    required int timeRemaining,
    required int hintsRemaining,
  }) async {
    await init();

    final progress = SavedGameProgress(
      letterRound: letterRound,
      completedLetters: completedLetters,
      score: score,
      timeRemaining: timeRemaining,
      hintsRemaining: hintsRemaining,
      savedAt: DateTime.now(),
    );

    await _prefs!.setString(_savedProgressKey, jsonEncode(progress.toJson()));
  }

  /// Load saved game progress (returns null if none exists)
  Future<SavedGameProgress?> loadGameProgress() async {
    await init();

    final jsonString = _prefs!.getString(_savedProgressKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SavedGameProgress.fromJson(json);
    } catch (e) {
      // Corrupted data, clear it
      await clearGameProgress();
      return null;
    }
  }

  /// Check if there's saved game progress
  Future<bool> hasSavedProgress() async {
    await init();
    return _prefs!.containsKey(_savedProgressKey);
  }

  /// Clear saved game progress (called when game ends)
  Future<void> clearGameProgress() async {
    await init();
    await _prefs!.remove(_savedProgressKey);
  }

  // ============================================
  // STAR CURRENCY PERSISTENCE
  // ============================================

  /// Save current star balance
  Future<void> saveStars(int stars) async {
    await init();
    await _prefs!.setInt(_starsKey, stars);
  }

  /// Load saved star balance (defaults to starting stars if none saved)
  Future<int> loadStars() async {
    await init();
    // Default to StarConfig.startingStars (2) if no stars saved
    return _prefs!.getInt(_starsKey) ?? 2;
  }
}
