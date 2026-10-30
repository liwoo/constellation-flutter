import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'audio_engine.dart';

AudioEngine createAudioEngine() => WebAudioEngine();

/// Web Audio API engine: one shared AudioContext, decoded buffers, and a
/// fresh AudioBufferSourceNode per one-shot (cheap, polyphonic, zero-latency).
class WebAudioEngine implements AudioEngine {
  web.AudioContext? _ctx;
  web.GainNode? _musicGain;
  web.AudioBufferSourceNode? _music;
  final _buffers = <String, web.AudioBuffer>{};
  bool _suspendedByApp = false;

  static const _unlockEvents = ['pointerdown', 'pointerup', 'touchend', 'click', 'keydown'];
  JSFunction? _unlockListener;

  @override
  Future<void> init() async {
    final ctx = web.AudioContext();
    _ctx = ctx;
    final musicGain = ctx.createGain();
    musicGain.gain.value = 0;
    musicGain.connect(ctx.destination);
    _musicGain = musicGain;

    // Browsers start the context suspended until a user gesture. Listen at the
    // DOM level (capture phase) because only certain native events count as
    // activation - e.g. iOS Safari needs touchend/pointerup, not pointerdown.
    _unlockListener = ((web.Event _) => _unlock()).toJS;
    for (final type in _unlockEvents) {
      web.document.addEventListener(
        type,
        _unlockListener,
        web.AddEventListenerOptions(capture: true),
      );
    }
  }

  void _unlock() {
    final ctx = _ctx;
    if (ctx == null || _suspendedByApp) return;
    if (ctx.state != 'running') {
      ctx.resume();
    }
  }

  @override
  Future<void> load(String key, String assetPath) async {
    final ctx = _ctx;
    if (ctx == null) return;
    final data = await rootBundle.load(assetPath);
    // decodeAudioData detaches its input, so hand it a private copy.
    final bytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    _buffers[key] = await ctx.decodeAudioData(bytes.buffer.toJS).toDart;
  }

  @override
  bool isLoaded(String key) => _buffers.containsKey(key);

  @override
  void play(String key, {double volume = 1.0, double rate = 1.0}) {
    final ctx = _ctx;
    final buffer = _buffers[key];
    if (ctx == null || buffer == null || ctx.state != 'running') return;
    try {
      final source = ctx.createBufferSource()
        ..buffer = buffer
        ..playbackRate.value = rate;
      final gain = ctx.createGain()..gain.value = volume;
      source.connect(gain);
      gain.connect(ctx.destination);
      source.start();
    } catch (e) {
      debugPrint('WebAudioEngine: play($key) failed - $e');
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
    final ctx = _ctx;
    final buffer = _buffers[key];
    final gain = _musicGain;
    if (ctx == null || buffer == null || gain == null) return;
    _stopMusicSource(ctx.currentTime + 0.3);
    final source = ctx.createBufferSource()
      ..buffer = buffer
      ..loop = true
      ..loopStart = loopStart.inMicroseconds / 1e6
      ..loopEnd = loopEnd.inMicroseconds / 1e6;
    source.connect(gain);
    // If the context is still locked, this is queued and starts on unlock.
    source.start();
    _music = source;
    _ramp(volume, fadeIn);
  }

  @override
  void stopMusic({Duration fadeOut = const Duration(milliseconds: 800)}) {
    final ctx = _ctx;
    if (ctx == null) return;
    _ramp(0, fadeOut);
    _stopMusicSource(ctx.currentTime + fadeOut.inMilliseconds / 1000);
  }

  void _stopMusicSource(num when) {
    final music = _music;
    _music = null;
    if (music == null) return;
    try {
      music.stop(when);
    } catch (_) {}
  }

  @override
  void setMusicVolume(double volume, {Duration fade = const Duration(milliseconds: 400)}) {
    _ramp(volume, fade);
  }

  void _ramp(double to, Duration over) {
    final ctx = _ctx;
    final gain = _musicGain;
    if (ctx == null || gain == null) return;
    final now = ctx.currentTime;
    gain.gain
      ..cancelScheduledValues(now)
      ..setValueAtTime(gain.gain.value, now)
      ..linearRampToValueAtTime(to, now + over.inMilliseconds / 1000);
  }

  @override
  void suspend() {
    _suspendedByApp = true;
    _ctx?.suspend();
  }

  @override
  void resume() {
    _suspendedByApp = false;
    _ctx?.resume();
  }
}
