part of 'main_menu_cubit.dart';

/// {@template main_menu}
/// MainMenuState description
/// {@endtemplate}
class MainMenuState extends Equatable {
  /// {@macro main_menu}
  const MainMenuState({
    this.highScore = 0,
    this.gamesPlayed = 0,
    this.soundEnabled = true,
    this.playerName = 'Player',
  });

  final int highScore;
  final int gamesPlayed;
  final bool soundEnabled;
  final String playerName;

  @override
  List<Object> get props => [highScore, gamesPlayed, soundEnabled, playerName];

  /// Creates a copy of the current MainMenuState with property changes
  MainMenuState copyWith({
    int? highScore,
    int? gamesPlayed,
    bool? soundEnabled,
    String? playerName,
  }) {
    return MainMenuState(
      highScore: highScore ?? this.highScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      playerName: playerName ?? this.playerName,
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
