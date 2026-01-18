import 'package:flutter/foundation.dart';

/// Sound effects available in the game
enum GameSound {
  letterSelect,
  wordCorrect,
  wordWrong,
  wheelLand,
  wheelSpin,
  buttonClick,
  gameWin,
  gameLose,
  timeWarning,
  jackpotReveal,
  roundComplete,
  mysteryReward,
  mysteryPenalty,
  mysteryActivate,
}

/// Audio service singleton - NO-OP stub
/// Audio functionality removed for SPM compatibility
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool _soundEnabled = true;

  /// Always returns true (stubbed)
  bool get isInitialized => true;

  /// Whether sound is currently enabled
  bool get soundEnabled => _soundEnabled;

  /// Initialize the audio engine (no-op)
  Future<void> init() async {
    debugPrint('AudioService: Stubbed - no audio support');
  }

  /// Preload sounds (no-op)
  Future<void> preloadSounds() async {}

  /// Play a sound effect (no-op)
  void play(GameSound sound) {}

  /// Play a looping sound (no-op)
  void playLoop(GameSound sound) {}

  /// Stop the currently looping sound (no-op)
  void stopLoop() {}

  /// Enable or disable sound effects
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  /// Toggle sound on/off
  void toggleSound() {
    setSoundEnabled(!_soundEnabled);
  }

  /// Clean up resources (no-op)
  Future<void> dispose() async {}
}