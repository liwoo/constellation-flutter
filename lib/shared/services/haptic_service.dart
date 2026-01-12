import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Haptic feedback service singleton
/// Provides consistent tactile feedback across iOS and Android
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool _hapticsEnabled = true;
  bool _canVibrate = false;
  bool _initialized = false;

  /// Whether haptics are currently enabled
  bool get hapticsEnabled => _hapticsEnabled;

  /// Whether the device supports haptic feedback
  bool get canVibrate => _canVibrate;

  /// Initialize the haptic service
  /// Call this during app startup
  Future<void> init() async {
    if (_initialized) return;

    try {
      _canVibrate = await Haptics.canVibrate();
      _initialized = true;
      debugPrint('HapticService: Initialized (canVibrate: $_canVibrate)');
    } catch (e) {
      debugPrint('HapticService: Failed to initialize - $e');
      _canVibrate = false;
      _initialized = true;
    }
  }

  /// Light impact - for subtle feedback (letter hover)
  Future<void> light() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.light);
    } catch (e) {
      // Fallback to built-in
      await HapticFeedback.lightImpact();
    }
  }

  /// Medium impact - for confirmations (letter selected)
  Future<void> medium() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.medium);
    } catch (e) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Heavy impact - for significant events (wheel land, correct answer)
  Future<void> heavy() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.heavy);
    } catch (e) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Selection click - for button taps
  Future<void> selection() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.selection);
    } catch (e) {
      await HapticFeedback.selectionClick();
    }
  }

  /// Success pattern - for positive feedback (correct word)
  Future<void> success() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.success);
    } catch (e) {
      // Fallback: heavy + light pattern
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    }
  }

  /// Warning pattern - for alerts (time running low)
  Future<void> warning() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.warning);
    } catch (e) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Error pattern - for negative feedback (wrong word)
  Future<void> error() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.error);
    } catch (e) {
      // Fallback: quick double vibration pattern
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.mediumImpact();
    }
  }

  /// Rigid impact - for firm feedback
  Future<void> rigid() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.rigid);
    } catch (e) {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Soft impact - for gentle feedback
  Future<void> soft() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.soft);
    } catch (e) {
      await HapticFeedback.lightImpact();
    }
  }

  /// Double tap pattern - for bonus rewards (time bonus)
  Future<void> doubleTap() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    try {
      await Haptics.vibrate(HapticsType.heavy);
      await Future.delayed(const Duration(milliseconds: 80));
      await Haptics.vibrate(HapticsType.heavy);
    } catch (e) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    }
  }

  /// Enable or disable haptic feedback
  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
    debugPrint('HapticService: Haptics ${enabled ? "enabled" : "disabled"}');
  }

  /// Toggle haptics on/off
  void toggleHaptics() {
    setHapticsEnabled(!_hapticsEnabled);
  }
}
