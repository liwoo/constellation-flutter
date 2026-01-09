# Constellation - Game Specification

## Overview
Constellation is a word-building game where players connect letters arranged in a star constellation pattern to form words within a time limit. Letters carry point values similar to Scrabble, with scoring multipliers for longer words.

---

## Core Gameplay

### Game Board Layout
- **Top Section**: Word display area where successfully formed words appear
- **Bottom Section**: Randomized star constellation of letters, each with visible point values

### Mechanics
1. Player connects letters by drawing/tapping through them
2. Connected letters form a word candidate
3. Valid words are submitted and appear in the top section
4. Points are calculated and added to the score
5. Game continues until the timer expires

---

## Scoring System

### Base Letter Points
Letters are scored like Scrabble - harder/rarer letters have higher point values:

| Points | Letters |
|--------|---------|
| 1 | A, E, I, O, U, L, N, S, T, R |
| 2 | D, G |
| 3 | B, C, M, P |
| 4 | F, H, V, W, Y |
| 5 | K |
| 8 | J, X |
| 10 | Q, Z |

### Letter Repetition Penalty
- First use of a letter: **100%** of point value
- Second use: **50%** of point value
- Third use: **25%** of point value
- And so on (halved each subsequent use)

### Word Length Multipliers
| Word Length | Multiplier |
|-------------|------------|
| 1-9 letters | 1x |
| 10-14 letters | 2x |
| 15-19 letters | 4x |
| 20+ letters | 8x |

### Score Calculation
```
Word Score = (Sum of Letter Points with Repetition Penalty) × Length Multiplier
```

---

## Screens

### 1. Main Menu
- Start Game button
- Settings button
- High Scores (future)

### 2. Game Screen
- Timer display
- Current score
- Word display area (top)
- Letter constellation (bottom)
- Pause/Menu button

### 3. Settings Screen
- Sound on/off
- Music on/off
- Timer duration selection
- Category selection (future)

---

## Technical Architecture

### Tech Stack
- **Framework**: Flutter
- **State Management**: Cubit (flutter_bloc)
- **Code Generation**: Mason CLI with feature_brick

### Feature Generation Command
```bash
mason make feature_brick --feature_name <name> --state_management cubit
```

### Project Structure
```
lib/
├── main.dart
├── app/
│   └── app.dart
├── features/
│   ├── main_menu/
│   │   ├── cubit/
│   │   │   ├── cubit.dart
│   │   │   ├── main_menu_cubit.dart
│   │   │   └── main_menu_state.dart
│   │   ├── view/
│   │   │   └── main_menu_page.dart
│   │   ├── widgets/
│   │   │   ├── main_menu_body.dart
│   │   │   └── widgets.dart
│   │   └── main_menu.dart
│   ├── game/
│   │   ├── cubit/
│   │   │   ├── cubit.dart
│   │   │   ├── game_cubit.dart
│   │   │   └── game_state.dart
│   │   ├── view/
│   │   │   └── game_page.dart
│   │   ├── widgets/
│   │   │   ├── game_body.dart
│   │   │   └── widgets.dart
│   │   └── game.dart
│   └── settings/
│       ├── cubit/
│       │   ├── cubit.dart
│       │   ├── settings_cubit.dart
│       │   └── settings_state.dart
│       ├── view/
│       │   └── settings_page.dart
│       ├── widgets/
│       │   ├── settings_body.dart
│       │   └── widgets.dart
│       └── settings.dart
├── services/
│   ├── game_engine/
│   │   └── game_engine_service.dart
│   ├── scoring/
│   │   └── scoring_service.dart
│   └── dictionary/
│       └── dictionary_service.dart
└── shared/
    ├── models/
    ├── widgets/
    └── constants/
```

### Services

| Service | Responsibility |
|---------|----------------|
| **GameEngineService** | Timer management, game state, letter generation, word validation flow |
| **ScoringService** | Point calculation, multipliers, repetition tracking |
| **DictionaryService** | Word validation against dictionary |

---

## Future Enhancements
- Word categories (Animals, Food, Places, etc.)
- Difficulty levels
- Multiplayer mode
- Daily challenges
- Achievements
- Leaderboards
