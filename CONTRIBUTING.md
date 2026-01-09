# Contributing to Constellation

First off, thank you for considering contributing to Constellation! It's people like you that make this game better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)

## Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inclusive environment. Please be respectful and constructive in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/constellation_app.git
   cd constellation_app
   ```
3. **Add the upstream remote**:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/constellation_app.git
   ```
4. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title** describing the issue
- **Steps to reproduce** the behavior
- **Expected behavior** vs what actually happened
- **Screenshots** if applicable
- **Device/platform** information (iOS, Android, version, etc.)
- **Flutter version** (`flutter --version`)

### Suggesting Features

Feature suggestions are welcome! Please include:

- **Clear description** of the feature
- **Use case** - why would this be useful?
- **Mockups or examples** if you have them

### Contributing Code

Great areas to contribute:

| Area | Description | Difficulty |
|------|-------------|------------|
| New Categories | Add word categories to the game | Easy |
| Bug Fixes | Fix reported issues | Easy-Medium |
| Animations | Improve visual feedback | Medium |
| Sound Effects | Add audio feedback | Medium |
| Accessibility | Screen reader support, contrast | Medium |
| Localization | Add new languages | Medium |
| Tests | Increase test coverage | Medium |
| New Features | Power-ups, multiplayer, etc. | Hard |

## Development Setup

### Prerequisites

- Flutter SDK 3.10.1+
- Dart SDK 3.10.1+
- Your preferred IDE (VS Code, Android Studio, IntelliJ)

### Setup Steps

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run analyzer
flutter analyze
```

### Project Structure

```
lib/
├── app/           # App configuration, routing
├── game/          # Game feature (cubit, view, widgets)
├── main_menu/     # Main menu feature
├── settings/      # Settings feature
└── shared/        # Shared code (constants, theme, widgets)
```

## Pull Request Process

### Before Submitting

1. **Update your branch** with the latest upstream changes:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run the analyzer** and fix any issues:
   ```bash
   flutter analyze
   ```

3. **Run tests** and ensure they pass:
   ```bash
   flutter test
   ```

4. **Format your code**:
   ```bash
   dart format lib/
   ```

### Submitting Your PR

1. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub with:
   - Clear title describing the change
   - Description of what was changed and why
   - Screenshots for UI changes
   - Reference to any related issues

3. **Respond to feedback** - reviewers may request changes

### PR Checklist

- [ ] Code follows the project style guidelines
- [ ] Self-reviewed my code
- [ ] Added comments for complex logic
- [ ] No new warnings from `flutter analyze`
- [ ] Tests pass locally
- [ ] Updated documentation if needed

## Style Guidelines

### Dart/Flutter Style

Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

- Use `camelCase` for variables and functions
- Use `PascalCase` for classes and types
- Use `snake_case` for file names
- Prefer `const` constructors
- Keep lines under 80 characters when possible

### Commit Messages

Use conventional commit format:

```
type: short description

Longer description if needed.

Fixes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Widget Guidelines

1. **Single responsibility** - one widget, one job
2. **Composition over inheritance** - build complex UIs from simple widgets
3. **Use constants** - `AppSpacing`, `AppColors`, `AppBorderRadius`
4. **Private widgets** - prefix with `_` for file-private widgets
5. **Document public APIs** - use `///` doc comments

### Example Widget

```dart
/// A button that glows when active.
///
/// Used in the main menu for navigation actions.
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isGlowing = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isGlowing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple,
          boxShadow: isGlowing ? [/* glow shadow */] : null,
        ),
        child: Text(label),
      ),
    );
  }
}
```

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

Thank you for contributing!
