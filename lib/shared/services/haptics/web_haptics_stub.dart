/// No-op outside the browser - native haptics go through `haptic_feedback`.
class WebHaptics {
  static bool get isSupported => false;

  /// [pattern] alternates vibrate/pause durations in milliseconds.
  static void vibrate(List<int> pattern) {}
}
