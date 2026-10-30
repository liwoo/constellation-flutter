part of 'settings_cubit.dart';

/// {@template settings}
/// SettingsState description
/// {@endtemplate}
class SettingsState extends Equatable {
  /// {@macro settings}
  const SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
  });

  /// Whether sound effects are enabled
  final bool soundEnabled;

  /// Whether background music is enabled
  final bool musicEnabled;

  /// Whether haptic feedback is enabled
  final bool hapticsEnabled;

  @override
  List<Object> get props => [soundEnabled, musicEnabled, hapticsEnabled];

  /// Creates a copy of the current SettingsState with property changes
  SettingsState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

/// {@template settings_initial}
/// The initial state of SettingsState
/// {@endtemplate}
class SettingsInitial extends SettingsState {
  /// {@macro settings_initial}
  const SettingsInitial() : super();
}
