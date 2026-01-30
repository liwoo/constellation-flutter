part of 'main_menu_cubit.dart';

/// High score entry for leaderboard display
class HighScoreEntry extends Equatable {
  const HighScoreEntry({
    required this.rank,
    required this.score,
    required this.lettersCompleted,
    required this.timestamp,
  });

  final int rank;
  final int score;
  final int lettersCompleted;
  final DateTime timestamp;

  @override
  List<Object> get props => [rank, score, lettersCompleted, timestamp];
}

/// {@template main_menu}
/// MainMenuState description
/// {@endtemplate}
class MainMenuState extends Equatable {
  /// {@macro main_menu}
  const MainMenuState({
    this.highScore = 0,
    this.gamesPlayed = 0,
    this.totalWins = 0,
    this.soundEnabled = true,
    this.playerName = 'Player',
    this.topScores = const [],
    this.stars = 0,
  });

  final int highScore;
  final int gamesPlayed;
  final int totalWins;
  final bool soundEnabled;
  final String playerName;
  final List<HighScoreEntry> topScores;
  final int stars;

  @override
  List<Object> get props => [highScore, gamesPlayed, totalWins, soundEnabled, playerName, topScores, stars];

  /// Creates a copy of the current MainMenuState with property changes
  MainMenuState copyWith({
    int? highScore,
    int? gamesPlayed,
    int? totalWins,
    bool? soundEnabled,
    String? playerName,
    List<HighScoreEntry>? topScores,
    int? stars,
  }) {
    return MainMenuState(
      highScore: highScore ?? this.highScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      playerName: playerName ?? this.playerName,
      topScores: topScores ?? this.topScores,
      stars: stars ?? this.stars,
    );
  }
}

/// {@template main_menu_initial}
/// The initial state of MainMenuState
/// {@endtemplate}
class MainMenuInitial extends MainMenuState {
  /// {@macro main_menu_initial}
  const MainMenuInitial() : super();
}
