/// General app constants
class AppConstants {
  const AppConstants._();

  // Game timers (in seconds)
  static const int timerShort = 60;
  static const int timerMedium = 90;
  static const int timerLong = 120;

  static const List<int> availableTimers = [
    timerShort,
    timerMedium,
    timerLong,
  ];

  // Constellation layout
  static const int minLetters = 15;
  static const int maxLetters = 20;

  // Letter bubble size
  static const double letterBubbleSize = 56.0;
  static const double letterBubbleSizeLarge = 64.0;

  // Badge sizes
  static const double badgeSizeSmall = 20.0;
  static const double badgeSizeMedium = 32.0;
  static const double badgeSizeLarge = 48.0;

  // Animation durations
  static const int animationDurationShort = 150;
  static const int animationDurationMedium = 300;
  static const int animationDurationLong = 500;

  // Game categories (for future implementation)
  static const List<String> categories = [
    'SPORTS BRANDS',
    'ANIMALS',
    'FOOD',
    'PLACES',
    'GENERAL',
  ];

  // Star ratings/difficulty
  static const int minDifficulty = 1;
  static const int maxDifficulty = 3;
}
