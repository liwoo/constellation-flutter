# Constellation

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Web-lightgrey)](https://flutter.dev/multi-platform)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A space-themed word puzzle game built with Flutter. Connect letters to form words and unlock the constellations!

## About the Game

Constellation is a word puzzle game where players connect floating letter bubbles to spell words within a given category. Set against a beautiful cosmic backdrop with twinkling stars and constellation patterns, the game combines the challenge of word puzzles with a relaxing space atmosphere.

### How to Play

1. **Connect letters** to form words that match the displayed category
2. **Drag between letters** to create connections
3. **Score points** based on word length and letter rarity
4. **Beat the clock** - complete as many words as possible before time runs out

## Features

- Space-themed UI with animated stars and constellation decorations
- Multiple word categories (Sports Brands, Animals, Food, Places, etc.)
- High score tracking
- Sound toggle
- Tutorial/How to Play guide
- Sci-fi typography using Google Fonts (Orbitron & Exo 2)

## Screenshots

| Main Menu | Gameplay | How to Play |
|:---------:|:--------:|:-----------:|
| ![Main Menu](screenshots/main_menu.png) | ![Gameplay](screenshots/gameplay.png) | ![How to Play](screenshots/how_to_play.png) |

> **Note:** To add screenshots, run the app and take screenshots on your device/simulator, then save them to the `screenshots/` folder.

See `ref/constellation-ui.jpeg` for the original UI design reference.

## Getting Started

### Prerequisites

- Flutter SDK 3.10.1 or higher
- Dart SDK 3.10.1 or higher
- iOS Simulator / Android Emulator or physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd constellation_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Running on specific platforms

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# macOS
flutter run -d macos

# Web
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app/
│   └── router.dart           # GoRouter navigation setup
├── game/
│   ├── cubit/                # Game state management
│   │   ├── game_cubit.dart
│   │   └── game_state.dart
│   ├── view/
│   │   └── game_page.dart
│   └── widgets/              # Game-specific widgets
│       ├── game_body.dart
│       ├── letter_constellation.dart
│       ├── word_display_area.dart
│       └── connection_painter.dart
├── main_menu/
│   ├── cubit/                # Menu state management
│   │   ├── main_menu_cubit.dart
│   │   └── main_menu_state.dart
│   ├── view/
│   │   └── main_menu_page.dart
│   └── widgets/
│       └── main_menu_body.dart
├── settings/
│   ├── cubit/                # Settings state management
│   ├── view/
│   └── widgets/
└── shared/
    ├── constants/            # App-wide constants
    │   ├── app_constants.dart
    │   ├── letter_points.dart
    │   ├── spacing_constants.dart
    │   └── word_multipliers.dart
    ├── theme/                # Theming configuration
    │   ├── app_theme.dart
    │   ├── color_schemes.dart
    │   ├── text_themes.dart
    │   └── theme_extensions.dart
    └── widgets/              # Reusable widgets
        ├── badge_widget.dart
        ├── category_banner.dart
        ├── constellation_line.dart
        ├── game_button.dart
        ├── gradient_background.dart
        ├── letter_bubble.dart
        └── star_decoration.dart
```

## Architecture

This project follows the **BLoC (Business Logic Component)** pattern using `flutter_bloc` for state management.

### State Management

Each feature has its own Cubit:

- **MainMenuCubit** - Manages menu state (high scores, sound settings, player name)
- **GameCubit** - Manages game state (letters, connections, score, timer)
- **SettingsCubit** - Manages app settings

### Navigation

Navigation is handled by `go_router` with the following routes:

| Route | Page | Description |
|-------|------|-------------|
| `/` | MainMenuPage | Home screen with play button and options |
| `/game` | GamePage | Main gameplay screen |
| `/settings` | SettingsPage | App settings |

## Theming

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Purple | `#9C27B0` | Buttons, accents |
| Primary Navy | `#1A237E` | Background gradient |
| Accent Gold | `#FFD700` | Primary buttons, highlights, stars |
| Accent Pink | `#E91E63` | Player avatar border |
| White | `#FFFFFF` | Text, letter bubbles |

### Typography

- **Orbitron** - Sci-fi display font for titles, headings, and buttons
- **Exo 2** - Readable sci-fi font for body text and labels

### Spacing Constants

```dart
AppSpacing.xs   = 4.0
AppSpacing.sm   = 8.0
AppSpacing.md   = 16.0
AppSpacing.lg   = 24.0
AppSpacing.xl   = 32.0
AppSpacing.xxl  = 48.0
```

## Contributing

We welcome contributions! Here's how you can help:

### Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run the analyzer: `flutter analyze`
5. Run tests: `flutter test`
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to the branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep widgets small and focused
- Use `const` constructors where possible

### Commit Messages

Use clear, descriptive commit messages:

```
feat: Add new power-up system
fix: Correct score calculation for bonus letters
docs: Update README with contribution guidelines
style: Format code according to dart standards
refactor: Extract letter selection logic to separate method
```

### Areas to Contribute

- **New Categories** - Add word categories in `lib/shared/constants/app_constants.dart`
- **Animations** - Improve letter selection and word completion animations
- **Sound Effects** - Implement audio feedback for game actions
- **Accessibility** - Improve screen reader support and color contrast
- **Localization** - Add support for multiple languages
- **Tests** - Increase test coverage for cubits and widgets

### File Naming Conventions

- Use snake_case for file names: `game_cubit.dart`
- Use PascalCase for class names: `GameCubit`
- Suffix pages with `_page.dart`: `main_menu_page.dart`
- Suffix widgets with `_body.dart` or descriptive name: `main_menu_body.dart`

### Widget Guidelines

1. **Keep widgets focused** - Each widget should do one thing well
2. **Use composition** - Build complex UIs from simple widgets
3. **Extract constants** - Use `AppSpacing`, `AppColors`, etc.
4. **Private widgets** - Prefix with underscore for file-private widgets: `_PlayerAvatar`

### Adding a New Feature

1. Create the feature folder under `lib/`
2. Add cubit with state in `cubit/` subfolder
3. Add page in `view/` subfolder
4. Add widgets in `widgets/` subfolder
5. Export via barrel files (e.g., `widgets.dart`, `cubit.dart`)
6. Register route in `app/router.dart`

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | ^8.1.6 | State management |
| equatable | ^2.0.5 | Value equality for state classes |
| go_router | ^14.6.2 | Declarative routing |
| google_fonts | ^7.0.0 | Custom typography |
| flutter_platform_widgets | ^7.0.1 | Platform-adaptive widgets |
| collection | ^1.18.0 | Collection utilities |

## Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/game/cubit/game_cubit_test.dart
```

## Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release
```

## Troubleshooting

### Common Issues

**Google Fonts not loading**
- Ensure you have internet connection on first run (fonts are cached after)
- Check that `google_fonts` package is in pubspec.yaml

**Build errors after pulling changes**
```bash
flutter clean
flutter pub get
flutter run
```

**iOS build issues**
```bash
cd ios
pod install --repo-update
cd ..
flutter run
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- UI Design inspiration from constellation and space themes
- Google Fonts for Orbitron and Exo 2 typefaces
- Flutter team for the amazing framework
