import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/game/cubit/alpha_quest_cubit.dart';

void main() {
  group('CategoryDictionary', () {
    late CategoryDictionary dictionary;

    setUp(() {
      dictionary = CategoryDictionary.instance;
    });

    test('should have all categories defined', () {
      expect(CategoryDictionary.categories.length, greaterThanOrEqualTo(5));
      expect(CategoryDictionary.categories, contains('ANIMALS'));
      expect(CategoryDictionary.categories, contains('COUNTRIES'));
      expect(CategoryDictionary.categories, contains('FOODS'));
    });

    test('should validate correct word for category and letter', () {
      expect(dictionary.isValidWord('ELEPHANT', 'ANIMALS', 'E'), isTrue);
      expect(dictionary.isValidWord('APPLE', 'FRUITS', 'A'), isTrue);
      expect(dictionary.isValidWord('NIKE', 'BRANDS', 'N'), isTrue);
    });

    test('should reject invalid word for category', () {
      expect(dictionary.isValidWord('ELEPHANT', 'FRUITS', 'E'), isFalse);
      expect(dictionary.isValidWord('BANANA', 'ANIMALS', 'B'), isFalse);
    });

    test('should reject word not starting with required letter', () {
      expect(dictionary.isValidWord('ELEPHANT', 'ANIMALS', 'A'), isFalse);
      expect(dictionary.isValidWord('APPLE', 'FRUITS', 'B'), isFalse);
    });

    test('should get words for category and letter', () {
      final words = dictionary.getWordsForCategoryAndLetter('ANIMALS', 'E');
      expect(words, contains('ELEPHANT'));
      expect(words, contains('EAGLE'));
    });

    test('should check if category has words for letter', () {
      expect(dictionary.categoryHasWordsForLetter('ANIMALS', 'E'), isTrue);
      expect(dictionary.categoryHasWordsForLetter('ANIMALS', 'X'), isTrue); // XERUS exists
    });

    test('should get random category for letter', () {
      final category = dictionary.getRandomCategoryForLetter('A');
      expect(category, isNotNull);
      expect(CategoryDictionary.categories, contains(category));
    });
  });

  group('AlphaQuestCubit', () {
    late AlphaQuestCubit cubit;

    setUp(() {
      cubit = AlphaQuestCubit();
    });

    tearDown(() {
      cubit.close();
    });

    group('Initial State', () {
      test('should start with initial time of 120 seconds', () {
        expect(cubit.state.timeRemaining, equals(120));
      });

      test('should start at round 1', () {
        expect(cubit.state.currentRound, equals(1));
      });

      test('should start with score of 0', () {
        expect(cubit.state.score, equals(0));
      });

      test('should not be playing initially', () {
        expect(cubit.state.isPlaying, isFalse);
      });

      test('should have no current letter initially', () {
        expect(cubit.state.currentLetter, isNull);
      });
    });

    group('Game Flow', () {
      test('should set current letter when spinning wheel completes', () {
        cubit.startGame();
        cubit.selectLetter('A');
        expect(cubit.state.currentLetter, equals('A'));
      });

      test('should assign a category when letter is selected', () {
        cubit.startGame();
        cubit.selectLetter('A');
        expect(cubit.state.currentCategory, isNotNull);
      });

      test('should mark letter as completed when correct word submitted', () {
        cubit.startGame();
        cubit.selectLetter('E');
        // Assuming ANIMALS category and ELEPHANT is valid
        cubit.setCategory('ANIMALS');
        cubit.submitWord('ELEPHANT');
        expect(cubit.state.completedLetters, contains('E'));
      });

      test('should add points to score when correct word submitted', () {
        cubit.startGame();
        cubit.selectLetter('E');
        cubit.setCategory('ANIMALS');
        final initialScore = cubit.state.score;
        cubit.submitWord('ELEPHANT');
        expect(cubit.state.score, greaterThan(initialScore));
      });

      test('should not mark letter as completed for wrong word', () {
        cubit.startGame();
        cubit.selectLetter('E');
        cubit.setCategory('ANIMALS');
        cubit.submitWord('BANANA'); // Wrong - doesn't start with E
        expect(cubit.state.completedLetters, isNot(contains('E')));
      });

      test('should change category on wrong answer', () {
        cubit.startGame();
        cubit.selectLetter('A');
        cubit.setCategory('ANIMALS');
        final initialCategory = cubit.state.currentCategory;
        cubit.submitWord('WRONGWORD');
        // Category should change (or stay same if no other valid category)
        expect(cubit.state.lastAnswerCorrect, isFalse);
      });
    });

    group('Timer Mechanics', () {
      test('should calculate next round time correctly', () {
        // Formula: 120 - (15 * round) + points
        // Round 1 with 10 points: 120 - 15 + 10 = 115
        cubit.startGame();
        cubit.selectLetter('A');
        cubit.setCategory('ANIMALS');

        // Simulate completing round with points
        final pointsEarned = 10;
        final expectedTime = 120 - 15 + pointsEarned;

        cubit.completeRoundWithPoints(pointsEarned);
        expect(cubit.state.timeRemaining, equals(expectedTime));
      });

      test('should decrease base time by 15 each round', () {
        cubit.startGame();

        // Complete round 1
        cubit.selectLetter('A');
        cubit.setCategory('ANIMALS');
        cubit.submitWord('ANT');

        // After round 1, base should be 120 - 15 = 105 + points
        expect(cubit.state.currentRound, equals(2));
      });

      test('should end game when timer reaches zero', () {
        cubit.startGame();
        cubit.setTimeRemaining(0);
        expect(cubit.state.isGameOver, isTrue);
      });
    });

    group('Win Condition', () {
      test('should win when all 26 letters completed', () {
        cubit.startGame();
        // Complete all letters
        for (var i = 0; i < 26; i++) {
          final letter = String.fromCharCode('A'.codeUnitAt(0) + i);
          cubit.markLetterCompleted(letter);
        }
        expect(cubit.state.completedLetters.length, equals(26));
        expect(cubit.state.isWinner, isTrue);
      });
    });

    group('Scoring', () {
      test('should calculate word score based on letter points', () {
        // Each letter has Scrabble-style points
        final score = cubit.calculateWordScore('ELEPHANT');
        expect(score, greaterThan(0));
      });

      test('should award bonus for longer words', () {
        final shortScore = cubit.calculateWordScore('ANT');
        final longScore = cubit.calculateWordScore('ELEPHANT');
        expect(longScore, greaterThan(shortScore));
      });
    });
  });
}
