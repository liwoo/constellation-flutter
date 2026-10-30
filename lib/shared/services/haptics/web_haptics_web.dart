import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Browser haptics.
///
/// - Android Chrome/Firefox: the Vibration API (`navigator.vibrate`).
/// - iOS Safari 18+: no Vibration API, but toggling a hidden
///   `<input type="checkbox" switch>` fires the system "switch" haptic. Each
///   pulse in a pattern becomes one tick. Safari only honours this during
///   (or shortly after) a user gesture, which covers taps and drags.
class WebHaptics {
  static final bool _hasVibrationApi =
      (web.window.navigator as JSObject).has('vibrate');

  static final bool _isIOS = () {
    final nav = web.window.navigator;
    final ua = nav.userAgent;
    return ua.contains('iPhone') ||
        ua.contains('iPad') ||
        // iPadOS reports itself as a Mac.
        (ua.contains('Macintosh') && nav.maxTouchPoints > 1);
  }();

  static web.HTMLLabelElement? _switchLabel;

  static bool get isSupported => _hasVibrationApi || _isIOS;

  /// [pattern] alternates vibrate/pause durations in milliseconds.
  static void vibrate(List<int> pattern) {
    if (pattern.isEmpty) return;
    try {
      if (_hasVibrationApi) {
        web.window.navigator.vibrate(pattern.map((ms) => ms.toJS).toList().toJS);
      } else if (_isIOS) {
        _iosPattern(pattern);
      }
    } catch (_) {
      // Haptics are best-effort.
    }
  }

  static void _iosPattern(List<int> pattern) {
    // Fire a tick at the start of each "on" segment.
    var offset = 0;
    for (var i = 0; i < pattern.length; i++) {
      if (i.isEven) {
        if (offset == 0) {
          _iosTick();
        } else {
          Timer(Duration(milliseconds: offset), _iosTick);
        }
      }
      offset += pattern[i];
    }
  }

  static void _iosTick() {
    final label = _switchLabel ??= _createSwitch();
    label.click();
  }

  static web.HTMLLabelElement _createSwitch() {
    final input = web.document.createElement('input') as web.HTMLInputElement
      ..type = 'checkbox'
      ..setAttribute('switch', '');
    final label = web.document.createElement('label') as web.HTMLLabelElement
      ..setAttribute('aria-hidden', 'true')
      ..style.display = 'none';
    label.appendChild(input);
    web.document.body?.appendChild(label);
    return label;
  }
}
