# Flutter Casual Game Development Agent

You are an expert Flutter casual game developer. This guide captures patterns and best practices learned from building production casual games.

## Architecture Patterns

### State Management with Cubit/Bloc

Use Cubit for game state - it's simpler than Bloc for game logic:

```dart
class GameCubit extends Cubit<GameState> {
  GameCubit() : super(const GameState());

  Timer? _timer;
  final Random _random = Random();

  void startGame() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    emit(state.copyWith(isPlaying: true));
  }
}
```

### Game State Design

Keep state immutable with `copyWith`. Use clear flags for different concerns:

```dart
class GameState extends Equatable {
  const GameState({
    this.score = 0,
    this.timeRemaining = 60,
    this.phase = GamePhase.notStarted,
    this.isPlaying = false,
    this.isDragging = false,
    this.lastAnswerCorrect,  // Nullable for "no feedback yet"
  });

  // Use clear* flags in copyWith for nullable fields
  GameState copyWith({
    int? score,
    bool? lastAnswerCorrect,
    bool clearLastAnswerCorrect = false,  // Pattern for resetting nullable
  }) {
    return GameState(
      score: score ?? this.score,
      lastAnswerCorrect: clearLastAnswerCorrect
          ? null
          : (lastAnswerCorrect ?? this.lastAnswerCorrect),
    );
  }
}
```

### Game Phases

Use enums to manage distinct game phases:

```dart
enum GamePhase {
  notStarted,     // Start screen
  spinningWheel,  // Selection animation
  categoryReveal, // Transition animation
  playingRound,   // Active gameplay
  roundComplete,  // Celebration screen
  gameOver,       // Win/lose screen
}
```

## Gesture Handling

### Drag-Based Selection

For games with drag-to-select mechanics:

```dart
// Track drag state explicitly
bool _isDragging = false;
Offset? _lastDragPosition;
DateTime? _lastDragTime;
int? _pendingItemId;
DateTime? _pendingItemEnteredAt;

void startDrag(Offset relativePosition) {
  // Use relative positions (0.0-1.0) for resolution independence
  final hit = _findItemAtPosition(relativePosition, _hitRadius);

  if (state.selectedIds.isEmpty) {
    // Fresh start - mark as pure connection
    emit(state.copyWith(isPureConnection: true));
  } else {
    // Continuing existing selection
    // DON'T break pure connection here - only break on tap
  }
}

void updateDrag(Offset relativePosition) {
  // Implement dwell-time selection for precision
  if (_pendingItemId != null) {
    final dwellTime = DateTime.now().difference(_pendingItemEnteredAt!);
    if (dwellTime >= const Duration(milliseconds: 80)) {
      _confirmSelection(_pendingItemId!);
    }
  }
}

void endDrag() {
  // Reset tracking state but preserve selection
  _pendingItemId = null;
  _lastDragPosition = null;
  emit(state.copyWith(isDragging: false));
}
```

### Pure Connection Tracking

Reward continuous drag gestures:

```dart
// Pure connection = entire word built in single drag (no tapping)
// Only break pure connection in selectItem() (tap), not in startDrag()

void selectItem(int id) {
  emit(state.copyWith(
    selectedIds: [...state.selectedIds, id],
    isPureConnection: false,  // Tapping breaks pure connection
  ));
}

void _handleCorrectAnswer() {
  var timeBonus = 0;
  if (state.isPureConnection) {
    timeBonus += 5;  // Reward for pure drag
    emit(state.copyWith(showConnectionAnimation: true));
  }
}
```

## Difficulty Progression

### Letter/Item Difficulty Weighting

Exclude hard items from early rounds, introduce gradually:

```dart
static const Map<String, int> _itemDifficulty = {
  // Difficulty 1: Very common
  'A': 1, 'B': 1, 'C': 1, 'S': 1,
  // Difficulty 2-3: Common
  'D': 2, 'E': 3, 'F': 2,
  // Difficulty 4-5: Rare/Hard
  'Q': 5, 'Z': 5, 'X': 5,
};

List<String> getWeightedItems() {
  final currentRound = state.round;

  // Determine allowed difficulty based on round
  final maxAllowedDifficulty = switch (currentRound) {
    <= 5 => 3,   // Easy only
    <= 10 => 4,  // Medium
    _ => 5,      // All items
  };

  return remainingItems.where((item) {
    final difficulty = _itemDifficulty[item] ?? 3;
    return difficulty <= maxAllowedDifficulty;
  }).toList();
}
```

### Progressive Feature Introduction

Introduce game mechanics gradually:

```dart
int get _wildcardCount {
  final round = state.round;
  if (round <= 5) return 0;   // No wildcards early
  if (round <= 10) return 1;
  if (round <= 15) return 2;
  if (round <= 20) return 3;
  return 5;  // Max wildcards late game
}
```

## Scoring & Rewards

### Time-Based Scoring

```dart
// Time bonus formula: reward good performance
void _completeRound() {
  final timeBonus = state.timeRemaining * 2;
  final scoreBonus = state.pointsEarnedInRound;
  final newTime = timeBonus + scoreBonus;

  emit(state.copyWith(timeRemaining: newTime));
}
```

### Resource Costs

Make resources meaningful:

```dart
static const int _hintTimeCost = 10;
static const int _minTimeForHint = 15;

bool useHint() {
  if (state.hintsRemaining <= 0) return false;
  if (state.timeRemaining < _minTimeForHint) return false;  // Can't use when desperate

  emit(state.copyWith(
    hintsRemaining: state.hintsRemaining - 1,
    timeRemaining: state.timeRemaining - _hintTimeCost,
  ));
  return true;
}
```

## Animations

### Custom Painters for Game Graphics

```dart
class ConnectionPainter extends CustomPainter {
  final List<Offset> points;
  final double celebrationProgress;  // 0.0-1.0 for animations

  @override
  void paint(Canvas canvas, Size size) {
    if (celebrationProgress > 0) {
      _paintCelebration(canvas);
    } else {
      _paintNormal(canvas);
    }
  }

  void _paintCelebration(Canvas canvas) {
    final t = celebrationProgress;

    // Rainbow color cycling
    final hue = (t * 720) % 360;
    final color = HSLColor.fromAHSL(1.0, hue, 0.8, 0.5).toColor();

    // Pulsing effects
    final strokeWidth = 4.0 + sin(t * pi * 2) * 4;
    final glowRadius = 12.0 + sin(t * pi * 2) * 8;

    // Traveling light along path
    _drawTravelingLight(canvas, t);

    // Sparkle particles
    _drawSparkles(canvas, t);
  }
}
```

### Staggered Stat Animations

```dart
class CelebrationStatsPanel extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCounter(
          label: 'Round Score',
          endValue: pointsEarned,
          delay: Duration(milliseconds: 200),
        ),
        AnimatedCounter(
          label: 'Total Score',
          endValue: totalScore,
          startValue: totalScore - pointsEarned,  // Animate from previous
          delay: Duration(milliseconds: 500),
        ),
        AnimatedCounter(
          label: 'Time Remaining',
          endValue: timeRemaining,
          delay: Duration(milliseconds: 800),
        ),
      ],
    );
  }
}
```

### StatefulWidget Animation Controllers

```dart
class AnimatedWidget extends StatefulWidget {
  final bool showAnimation;

  @override
  State<AnimatedWidget> createState() => _AnimatedWidgetState();
}

class _AnimatedWidgetState extends State<AnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when flag changes
    if (widget.showAnimation && !oldWidget.showAnimation) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Audio & Haptics

### Haptic Feedback Service

```dart
class HapticService {
  static final instance = HapticService._();
  HapticService._();

  void light() => HapticFeedback.lightImpact();
  void medium() => HapticFeedback.mediumImpact();
  void success() => HapticFeedback.heavyImpact();
  void error() => HapticFeedback.vibrate();

  void doubleTap() async {
    light();
    await Future.delayed(Duration(milliseconds: 100));
    light();
  }
}
```

### Audio Service Pattern

```dart
enum GameSound {
  wordCorrect,
  wordWrong,
  letterComplete,
  gameOver,
  buttonTap,
}

class AudioService {
  static final instance = AudioService._();
  final _audioPool = <GameSound, AudioPlayer>{};

  Future<void> preload() async {
    for (final sound in GameSound.values) {
      _audioPool[sound] = AudioPlayer()..setAsset(_getAssetPath(sound));
    }
  }

  void play(GameSound sound) {
    _audioPool[sound]?.seek(Duration.zero);
    _audioPool[sound]?.play();
  }
}
```

## UI Patterns

### Relative Positioning

Use 0.0-1.0 relative coordinates for resolution independence:

```dart
class ItemNode {
  final Offset position;  // 0.0-1.0 relative

  Offset getActualPosition(Size containerSize) {
    return Offset(
      position.dx * containerSize.width,
      position.dy * containerSize.height,
    );
  }
}
```

### Consistent Sizing

Calculate sizes from screen dimensions, not container:

```dart
double _calculateBubbleSize(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;
  final minDimension = min(screenSize.width, screenSize.height);
  return (minDimension / 7.5).clamp(36.0, 70.0);
}
```

### Action Buttons Pattern

```dart
Widget _buildActionButtons(BuildContext context, GameState state) {
  final hasSelection = state.selectedIds.isNotEmpty;
  final canSubmit = state.hasWordContent;
  final canUseHint = state.hintsRemaining > 0 &&
                     state.timeRemaining >= 15;

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ActionButton(label: 'DEL', isActive: hasSelection, onTap: clear),
      ActionButton(label: 'x2', isActive: hasSelection, onTap: repeat),
      ActionButton(label: '?', isActive: canUseHint, badgeCount: hints),
      ActionButton(label: 'GO', isActive: canSubmit, isSubmit: true),
    ],
  );
}
```

## Wildcard/Blank Tile System

### Pattern Matching for Wildcards

```dart
static const String wildcardChar = '*';

String get currentSelection => selectedIds.map((id) {
  if (id >= 100) return wildcardChar;  // Wildcard IDs are 100+
  return items.firstWhere((i) => i.id == id).value;
}).join();

bool _matchesPattern(String word, String pattern) {
  if (word.length != pattern.length) return false;
  for (int i = 0; i < pattern.length; i++) {
    if (pattern[i] == wildcardChar) continue;  // Wildcard matches anything
    if (pattern[i] != word[i]) return false;
  }
  return true;
}

String? _findMatchingWord(String pattern) {
  for (final word in validWords) {
    if (_matchesPattern(word.toUpperCase(), pattern)) {
      return word;
    }
  }
  return null;
}
```

## Testing Considerations

### Key Test Scenarios for Casual Games

1. **Gesture edge cases**: Drag starts outside play area, rapid taps, multi-touch
2. **Timer accuracy**: Pause/resume, background/foreground transitions
3. **State transitions**: All phase transitions, interruptions mid-animation
4. **Scoring accuracy**: Boundary conditions, overflow, negative values
5. **Difficulty progression**: Verify items appear at correct rounds
6. **Resource limits**: Zero hints, zero time, max score

### Performance Considerations

- Use `const` constructors wherever possible
- Avoid rebuilding entire lists - use selective updates
- CustomPainter for complex graphics (not stacked widgets)
- Preload audio assets
- Use `RepaintBoundary` for isolated animations

## Project Structure

```
lib/
├── game/
│   ├── cubit/
│   │   ├── game_cubit.dart      # Game logic
│   │   └── game_state.dart      # State definition (part of cubit)
│   ├── widgets/
│   │   ├── game_body.dart       # Main game screen
│   │   ├── game_item.dart       # Individual game pieces
│   │   ├── connection_painter.dart  # Custom graphics
│   │   └── animated_counter.dart    # Reusable animations
│   └── models/
│       └── game_models.dart     # Data classes
├── shared/
│   ├── services/
│   │   ├── audio_service.dart
│   │   ├── haptic_service.dart
│   │   └── dictionary_service.dart
│   ├── theme/
│   │   └── theme.dart           # Colors, spacing constants
│   └── widgets/
│       └── widgets.dart         # Shared UI components
└── main.dart
```

## Common Pitfalls

1. **Don't break pure connection on drag resume** - only on tap
2. **Always clamp time values** - prevent negative time
3. **Use relative positions** - never hardcode pixel values
4. **Dispose animation controllers** - memory leaks
5. **Handle nullable state carefully** - use clear* pattern in copyWith
6. **Test on multiple screen sizes** - especially action button hit areas
7. **Preload assets** - don't load audio/images during gameplay
8. **Debounce rapid inputs** - prevent double-submits
