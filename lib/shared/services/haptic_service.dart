import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'haptics/web_haptics.dart';

/// Haptic feedback service singleton
/// Provides consistent tactile feedback across iOS, Android and the web
/// (Vibration API on Android browsers, switch-haptic on iOS Safari 18+).
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  static const _prefKey = 'haptics_enabled';

  bool _hapticsEnabled = true;
  bool _canVibrate = false;
  bool _initialized = false;
  SharedPreferences? _prefs;

  /// Whether haptics are currently enabled
  bool get hapticsEnabled => _hapticsEnabled;

  /// Whether the device supports haptic feedback
  bool get canVibrate => _canVibrate;

  /// Initialize the haptic service
  /// Call this during app startup
  Future<void> init() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _hapticsEnabled = _prefs!.getBool(_prefKey) ?? true;
    } catch (e) {
      debugPrint('HapticService: Failed to read preferences - $e');
    }

    if (kIsWeb) {
      _canVibrate = WebHaptics.isSupported;
      _initialized = true;
      debugPrint('HapticService: Web haptics (supported: $_canVibrate)');
      return;
    }

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

  /// Plays [type] natively, [webPattern] (vibrate/pause ms) in browsers, and
  /// [fallback] if the native plugin call fails.
  Future<void> _fire(
    HapticsType type,
    List<int> webPattern,
    Future<void> Function() fallback,
  ) async {
    if (!_hapticsEnabled || !_canVibrate) return;

    if (kIsWeb) {
      WebHaptics.vibrate(webPattern);
      return;
    }

    try {
      await Haptics.vibrate(type);
    } catch (e) {
      await fallback();
    }
  }

  /// Light impact - for subtle feedback (letter hover)
  Future<void> light() =>
      _fire(HapticsType.light, const [10], HapticFeedback.lightImpact);

  /// Medium impact - for confirmations (letter selected)
  Future<void> medium() =>
      _fire(HapticsType.medium, const [20], HapticFeedback.mediumImpact);

  /// Heavy impact - for significant events (wheel land, correct answer)
  Future<void> heavy() =>
      _fire(HapticsType.heavy, const [35], HapticFeedback.heavyImpact);

  /// Selection click - for button taps and wheel ticks
  Future<void> selection() =>
      _fire(HapticsType.selection, const [6], HapticFeedback.selectionClick);

  /// Magnetic snap - crisp, firm click when a letter connects
  Future<void> snap() =>
      _fire(HapticsType.rigid, const [18], HapticFeedback.heavyImpact);

  /// Success pattern - for positive feedback (correct word)
  Future<void> success() => _fire(
        HapticsType.success,
        const [30, 60, 20],
        () async {
          // Fallback: heavy + light pattern
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
        },
      );

  /// Warning pattern - for alerts (time running low)
  Future<void> warning() =>
      _fire(HapticsType.warning, const [25, 80, 25], HapticFeedback.mediumImpact);

  /// Error pattern - for negative feedback (wrong word)
  Future<void> error() => _fire(
        HapticsType.error,
        const [40, 50, 40, 50, 40],
        () async {
          // Fallback: quick double vibration pattern
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          await HapticFeedback.mediumImpact();
        },
      );

  /// Rigid impact - for firm feedback
  Future<void> rigid() =>
      _fire(HapticsType.rigid, const [25], HapticFeedback.heavyImpact);

  /// Soft impact - for gentle feedback
  Future<void> soft() =>
      _fire(HapticsType.soft, const [12], HapticFeedback.lightImpact);

  /// Double tap pattern - for bonus rewards (time bonus)
  Future<void> doubleTap() async {
    if (!_hapticsEnabled || !_canVibrate) return;

    if (kIsWeb) {
      WebHaptics.vibrate(const [35, 80, 35]);
      return;
    }

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
    _prefs?.setBool(_prefKey, enabled);
    debugPrint('HapticService: Haptics ${enabled ? "enabled" : "disabled"}');
  }

  /// Toggle haptics on/off
  void toggleHaptics() {
    setHapticsEnabled(!_hapticsEnabled);
  }
}
