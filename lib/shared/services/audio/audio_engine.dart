import 'audio_engine_native.dart'
    if (dart.library.js_interop) 'audio_engine_web.dart' as impl;

/// Low-level playback backend used by [AudioService].
///
/// Native platforms use SoLoud (low latency, true polyphony, pitch shifting,
/// gapless looping). Web uses the browser's Web Audio API directly so mixing
/// happens off the main thread and loops are sample-accurate.
abstract class AudioEngine {
  factory AudioEngine() => impl.createAudioEngine();

  /// Start the engine. Throws if audio is unavailable.
  Future<void> init();

  /// Decode an asset into memory under [key].
  Future<void> load(String key, String assetPath);

  bool isLoaded(String key);

  /// Fire-and-forget one-shot. [rate] changes pitch and speed together.
  void play(String key, {double volume = 1.0, double rate = 1.0});

  /// Start a looping music track, fading in from silence.
  ///
  /// [loopStart]/[loopEnd] define the sample-accurate loop region; playback
  /// begins at zero so any pre-roll plays once.
  void startMusic(
    String key, {
    required double volume,
    required Duration loopStart,
    required Duration loopEnd,
    Duration fadeIn,
  });

  void stopMusic({Duration fadeOut});

  /// Ramp the music to [volume] over [fade].
  void setMusicVolume(double volume, {Duration fade});

  /// Suspend all output (app backgrounded / tab hidden).
  void suspend();

  /// Resume output after [suspend].
  void resume();
}
