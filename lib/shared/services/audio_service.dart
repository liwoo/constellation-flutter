import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio/audio_engine.dart';

/// Sound effects available in the game.
///
/// Every file is synthesized by `tool/generate_audio.py`. Short, reactive
/// sounds are WAV (no decoder delay); longer ones are MP3 to keep the web
/// bundle small.
enum GameSound {
  // Building words
  magnetSnap('magnet_snap.wav', 0.55),
  connectFail('connect_fail.wav', 0.7),
  delete('delete.wav', 0.45),
  buttonTap('button_tap.wav', 0.35),

  // Word results
  bubblesRise('bubbles_rise.mp3', 0.75),
  wordCorrect('word_correct.mp3', 0.7),
  pureConnection('pure_connection.mp3', 0.75),
  wordWrong('word_wrong.wav', 0.55),

  // Round flow
  wheelTick('wheel_tick.wav', 0.3),
  wheelLand('wheel_land.mp3', 0.7),
  jackpotReveal('jackpot_reveal.mp3', 0.6),
  timeWarning('time_warning.wav', 0.35),
  counterTick('counter_tick.wav', 0.18),
  hint('hint.mp3', 0.6),

  // Mystery orbs
  mysteryActivate('mystery_activate.mp3', 0.6),
  mysteryReward('mystery_reward.mp3', 0.6),
  mysteryPenalty('mystery_penalty.wav', 0.45),

  // Shooting stars
  shootingStar('shooting_star.mp3', 0.6),
  shootingStarCatch('shooting_star_catch.mp3', 0.7),

  // Celebrations
  starEarned('star_earned.mp3', 0.75),
  roundComplete('round_complete.mp3', 0.75),
  gameWin('game_win.mp3', 0.85),
  gameLose('game_lose.mp3', 0.5);

  const GameSound(this.file, this.volume);

  /// File name inside `assets/audio/`.
  final String file;

  /// Mix level relative to the other sounds.
  final double volume;
}

/// Audio service singleton: sound effects + looping background music.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const _musicFile = 'music_ambient.mp3';
  static const _musicKey = 'music';
  static const double _musicVolume = 0.3;
  static const double _duckedMusicVolume = 0.1;

  // Must match MUSIC_* constants in tool/generate_audio.py: 16 bars at
  // 70 BPM with a 2 s pre-roll copied from the loop's tail.
  static const _musicLoopStart = Duration(seconds: 2);
  static const _musicLoopEnd = Duration(microseconds: 2000000 + 54857143);

  // Major-pentatonic ladder (semitones) - each successive letter in a chain
  // snaps a step higher, so building a word "climbs".
  static const _snapLadder = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21];

  static const _soundPrefKey = 'audio_sfx_enabled';
  static const _musicPrefKey = 'audio_music_enabled';

  AudioEngine? _engine;
  SharedPreferences? _prefs;
  AppLifecycleListener? _lifecycle;
  Timer? _duckTimer;
  final _lastPlayed = <GameSound, DateTime>{};

  bool _initialized = false;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _musicLoaded = false;
  bool _musicPaused = false;

  bool get isInitialized => _initialized;

  /// Whether sound effects are enabled.
  bool get soundEnabled => _soundEnabled;

  /// Whether background music is enabled.
  bool get musicEnabled => _musicEnabled;

  /// Load preferences and start the audio engine. Fast - does not decode
  /// any assets (see [preloadSounds]).
  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _soundEnabled = _prefs!.getBool(_soundPrefKey) ?? true;
      _musicEnabled = _prefs!.getBool(_musicPrefKey) ?? true;
    } catch (e) {
      debugPrint('AudioService: Failed to read preferences - $e');
    }

    try {
      final engine = AudioEngine();
      await engine.init();
      _engine = engine;
      _initialized = true;
    } catch (e) {
      debugPrint('AudioService: Audio unavailable - $e');
      return;
    }

    _lifecycle = AppLifecycleListener(
      onHide: () => _engine?.suspend(),
      onShow: () => _engine?.resume(),
    );
  }

  /// Decode all sounds, then start the background music. Safe to call
  /// without awaiting - sounds requested before they finish loading are
  /// silently skipped.
  Future<void> preloadSounds() async {
    final engine = _engine;
    if (engine == null) return;

    await Future.wait(GameSound.values.map((sound) async {
      try {
        await engine.load(sound.name, 'assets/audio/${sound.file}');
      } catch (e) {
        debugPrint('AudioService: Failed to load ${sound.file} - $e');
      }
    }));

    try {
      await engine.load(_musicKey, 'assets/audio/$_musicFile');
      _musicLoaded = true;
      final loaded = GameSound.values.where((s) => engine.isLoaded(s.name)).length;
      debugPrint('AudioService: Loaded $loaded/${GameSound.values.length} sounds + music');
      if (_musicEnabled) _startMusic();
    } catch (e) {
      debugPrint('AudioService: Failed to load music - $e');
    }
  }

  /// Play a sound effect.
  ///
  /// [rate] shifts pitch (1.0 = original). [volume] scales the sound's
  /// default mix level. [minInterval] drops repeats that arrive too quickly.
  void play(
    GameSound sound, {
    double volume = 1.0,
    double rate = 1.0,
    Duration minInterval = const Duration(milliseconds: 30),
  }) {
    if (!_soundEnabled) return;
    final engine = _engine;
    if (engine == null) return;

    final now = DateTime.now();
    final last = _lastPlayed[sound];
    if (last != null && now.difference(last) < minInterval) return;
    _lastPlayed[sound] = now;

    engine.play(sound.name, volume: sound.volume * volume, rate: rate);
  }

  /// Magnetic snap for connecting the [chainLength]th letter of a word.
  /// Pitch climbs a pentatonic ladder as the chain grows.
  void playSnap(int chainLength, {double volume = 1.0}) {
    final step = _snapLadder[(chainLength - 1).clamp(0, _snapLadder.length - 1)];
    play(
      GameSound.magnetSnap,
      volume: volume,
      rate: pow(2, step / 12).toDouble(),
      minInterval: Duration.zero,
    );
  }

  /// Play a sound after [delay] (e.g. to layer a chime over bubbles).
  void playDelayed(GameSound sound, Duration delay, {double volume = 1.0}) {
    Future.delayed(delay, () => play(sound, volume: volume));
  }

  /// Lower the music while a celebration plays, then bring it back.
  void duckMusic(Duration duration) {
    final engine = _engine;
    if (engine == null || !_musicEnabled || _musicPaused) return;
    _duckTimer?.cancel();
    engine.setMusicVolume(_duckedMusicVolume, fade: const Duration(milliseconds: 250));
    _duckTimer = Timer(duration, () {
      if (_musicEnabled && !_musicPaused) {
        engine.setMusicVolume(_musicVolume, fade: const Duration(milliseconds: 1500));
      }
    });
  }

  /// Silence the music (game paused). Sound effects keep playing.
  void pauseMusic() {
    if (_musicPaused) return;
    _musicPaused = true;
    _duckTimer?.cancel();
    _engine?.setMusicVolume(0, fade: const Duration(milliseconds: 300));
  }

  /// Bring the music back after [pauseMusic]
  void resumeMusic() {
    if (!_musicPaused) return;
    _musicPaused = false;
    if (_musicEnabled) {
      _engine?.setMusicVolume(_musicVolume, fade: const Duration(milliseconds: 800));
    }
  }

  void _startMusic() {
    if (!_musicLoaded) return;
    _engine?.startMusic(
      _musicKey,
      volume: _musicVolume,
      loopStart: _musicLoopStart,
      loopEnd: _musicLoopEnd,
    );
  }

  /// Enable or disable sound effects.
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _prefs?.setBool(_soundPrefKey, enabled);
  }

  /// Toggle sound effects on/off.
  void toggleSound() => setSoundEnabled(!_soundEnabled);

  /// Enable or disable background music.
  void setMusicEnabled(bool enabled) {
    if (_musicEnabled == enabled) return;
    _musicEnabled = enabled;
    _prefs?.setBool(_musicPrefKey, enabled);
    if (enabled) {
      _startMusic();
    } else {
      _duckTimer?.cancel();
      _engine?.stopMusic();
    }
  }

  /// Toggle background music on/off.
  void toggleMusic() => setMusicEnabled(!_musicEnabled);

  /// Stop music and release lifecycle hooks.
  Future<void> dispose() async {
    _duckTimer?.cancel();
    _lifecycle?.dispose();
    _engine?.stopMusic(fadeOut: Duration.zero);
  }
}
