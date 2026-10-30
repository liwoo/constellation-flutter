import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_engine.dart';

AudioEngine createAudioEngine() => SoLoudAudioEngine();

/// SoLoud-backed engine for iOS, Android, macOS, Windows and Linux.
class SoLoudAudioEngine implements AudioEngine {
  final _soloud = SoLoud.instance;
  final _sources = <String, AudioSource>{};
  SoundHandle? _music;

  @override
  Future<void> init() async {
    if (!_soloud.isInitialized) {
      await _soloud.init(bufferSize: 1024);
    }
    // Rapid letter snaps + counters can overlap heavily.
    _soloud.setMaxActiveVoiceCount(32);
    // Keep the device warm between sounds so the next snap isn't delayed by
    // a device restart, but still let it sleep when the game is idle.
    _soloud.setAudioDeviceIdleTimeout(const Duration(seconds: 20));
  }

  @override
  Future<void> load(String key, String assetPath) async {
    _sources[key] = await _soloud.loadAsset(assetPath);
  }

  @override
  bool isLoaded(String key) => _sources.containsKey(key);

  @override
  void play(String key, {double volume = 1.0, double rate = 1.0}) {
    final source = _sources[key];
    if (source == null || !_soloud.isInitialized) return;
    try {
      if (rate == 1.0) {
        _soloud.play(source, volume: volume);
      } else {
        // Start paused so the pitch change applies from the first sample.
        final handle = _soloud.play(source, volume: volume, paused: true);
        _soloud.setRelativePlaySpeed(handle, rate);
        _soloud.setPause(handle, false);
      }
    } catch (e) {
      debugPrint('SoLoudAudioEngine: play($key) failed - $e');
    }
  }

  @override
  void startMusic(
    String key, {
    required double volume,
    required Duration loopStart,
    required Duration loopEnd,
    Duration fadeIn = const Duration(seconds: 3),
  }) {
    final source = _sources[key];
    if (source == null || !_soloud.isInitialized) return;
    stopMusic(fadeOut: const Duration(milliseconds: 300));
    try {
      final handle = _soloud.play(
        source,
        volume: 0,
        looping: true,
        loopingStartAt: loopStart,
        loopingEndAt: loopEnd,
      );
      _soloud.fadeVolume(handle, volume, fadeIn);
      _music = handle;
    } catch (e) {
      debugPrint('SoLoudAudioEngine: startMusic failed - $e');
    }
  }

  @override
  void stopMusic({Duration fadeOut = const Duration(milliseconds: 800)}) {
    final handle = _music;
    _music = null;
    if (handle == null || !_isValid(handle)) return;
    try {
      _soloud.fadeVolume(handle, 0, fadeOut);
      _soloud.scheduleStop(handle, fadeOut);
    } catch (e) {
      debugPrint('SoLoudAudioEngine: stopMusic failed - $e');
    }
  }

  @override
  void setMusicVolume(double volume, {Duration fade = const Duration(milliseconds: 400)}) {
    final handle = _music;
    if (handle == null || !_isValid(handle)) return;
    try {
      _soloud.fadeVolume(handle, volume, fade);
    } catch (e) {
      debugPrint('SoLoudAudioEngine: setMusicVolume failed - $e');
    }
  }

  @override
  void suspend() {
    final handle = _music;
    if (handle != null && _isValid(handle)) _soloud.setPause(handle, true);
  }

  @override
  void resume() {
    final handle = _music;
    if (handle != null && _isValid(handle)) _soloud.setPause(handle, false);
  }

  bool _isValid(SoundHandle handle) =>
      _soloud.isInitialized && _soloud.getIsValidVoiceHandle(handle);
}
