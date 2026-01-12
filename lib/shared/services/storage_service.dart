import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/shared/models/models.dart';

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
  }
}
