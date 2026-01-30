import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:constellation_app/shared/services/storage_service.dart';

part 'main_menu_state.dart';

class MainMenuCubit extends Cubit<MainMenuState> {
  MainMenuCubit() : super(const MainMenuInitial()) {
    loadStats();
  }

  /// Load all stats from persistent storage
  Future<void> loadStats() async {
    final storage = StorageService.instance;

    final highScore = await storage.getHighScore();
    final gamesPlayed = await storage.getTotalGames();
    final totalWins = await storage.getTotalWins();
    final stars = await storage.loadStars();
    final topSessions = await storage.getTopScores(limit: 10);

    // Convert sessions to high score entries
    final topScores = topSessions.asMap().entries.map((entry) {
      final session = entry.value;
      return HighScoreEntry(
        rank: entry.key + 1,
        score: session.score,
        lettersCompleted: session.lettersCompleted,
        timestamp: session.timestamp,
      );
    }).toList();

    emit(state.copyWith(
      highScore: highScore,
      gamesPlayed: gamesPlayed,
      totalWins: totalWins,
      topScores: topScores,
      stars: stars,
    ));
  }

  void toggleSound() {
    emit(state.copyWith(soundEnabled: !state.soundEnabled));
  }

  void updatePlayerName(String name) {
    emit(state.copyWith(playerName: name));
  }

  void updateHighScore(int score) {
    if (score > state.highScore) {
      emit(state.copyWith(highScore: score));
    }
  }

  void incrementGamesPlayed() {
    emit(state.copyWith(gamesPlayed: state.gamesPlayed + 1));
  }

  /// Refresh stats after a game ends
  Future<void> refreshStats() async {
    await loadStats();
  }
}
