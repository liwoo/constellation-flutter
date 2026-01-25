import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Direction of a detected shake
enum ShakeDirection { left, right }

/// Service to detect shake patterns using the accelerometer.
/// Detects the cheat code: shake right, shake right, shake left
class ShakeDetectionService {
  ShakeDetectionService._();
  static final instance = ShakeDetectionService._();

  StreamSubscription<AccelerometerEvent>? _subscription;
  final List<ShakeDirection> _shakeSequence = [];
  DateTime? _lastShakeTime;
  double _lastX = 0;
  bool _isInShake = false;

  // Callbacks
  void Function()? onCheatDetected;

  /// Threshold for detecting a shake (m/s^2)
  static const double _shakeThreshold = 15.0;

  /// Time window to complete the sequence (ms)
  static const int _sequenceTimeoutMs = 2000;

  /// Minimum time between shakes (ms) to prevent double-detection
  static const int _shakeCooldownMs = 200;

  /// Start listening for shake patterns
  void startListening() {
    _subscription?.cancel();
    _shakeSequence.clear();
    _lastShakeTime = null;

    _subscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_onAccelerometerEvent);
  }

  /// Stop listening for shake patterns
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _shakeSequence.clear();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final now = DateTime.now();

    // Check for sequence timeout - reset if too much time passed
    if (_lastShakeTime != null) {
      final elapsed = now.difference(_lastShakeTime!).inMilliseconds;
      if (elapsed > _sequenceTimeoutMs) {
        _shakeSequence.clear();
      }
    }

    // Detect shake direction based on X acceleration
    // Positive X = device tilted/shaken right
    // Negative X = device tilted/shaken left
    final x = event.x;

    // Check if we're starting a new shake
    if (!_isInShake && x.abs() > _shakeThreshold) {
      // Cooldown check
      if (_lastShakeTime != null) {
        final elapsed = now.difference(_lastShakeTime!).inMilliseconds;
        if (elapsed < _shakeCooldownMs) return;
      }

      _isInShake = true;
      _lastX = x;
    }

    // Check if shake ended (acceleration returned to low)
    if (_isInShake && x.abs() < _shakeThreshold * 0.5) {
      _isInShake = false;

      // Determine direction based on the peak acceleration
      final direction = _lastX > 0 ? ShakeDirection.right : ShakeDirection.left;
      _registerShake(direction, now);
    }
  }

  void _registerShake(ShakeDirection direction, DateTime now) {
    _shakeSequence.add(direction);
    _lastShakeTime = now;

    // Check if we have the cheat sequence: right, right, left
    if (_shakeSequence.length >= 3) {
      final len = _shakeSequence.length;
      if (_shakeSequence[len - 3] == ShakeDirection.right &&
          _shakeSequence[len - 2] == ShakeDirection.right &&
          _shakeSequence[len - 1] == ShakeDirection.left) {
        // Cheat detected!
        _shakeSequence.clear();
        onCheatDetected?.call();
      }
    }

    // Keep sequence from growing too large
    if (_shakeSequence.length > 10) {
      _shakeSequence.removeAt(0);
    }
  }

  /// Dispose of resources
  void dispose() {
    stopListening();
  }
}
