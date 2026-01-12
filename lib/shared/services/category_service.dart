import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Model representing a word category with words organized by starting letter
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.wordsByLetter,
    this.difficulty = 5,
  });

  final int id;
  final String name;
  final Map<String, List<String>> wordsByLetter;
  /// Difficulty level from 1 (easy) to 10 (hard)
  final int difficulty;

  factory Category.fromJson(Map<String, dynamic> json) {
    final wordsData = json['words'] as Map<String, dynamic>;
    final wordsByLetter = <String, List<String>>{};

    for (final entry in wordsData.entries) {
      wordsByLetter[entry.key] = (entry.value as List).cast<String>();
    }

    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      wordsByLetter: wordsByLetter,
      difficulty: (json['difficulty'] as int?) ?? 5,
    );
  }

  /// Get all words in this category as a flat list
  List<String> get allWords {
    return wordsByLetter.values.expand((words) => words).toList();
  }

  /// Get words starting with a specific letter
  List<String> getWordsForLetter(String letter) {
    return wordsByLetter[letter.toUpperCase()] ?? [];
  }

  /// Check if this category has words for a specific letter
  bool hasWordsForLetter(String letter) {
    final words = wordsByLetter[letter.toUpperCase()];
    return words != null && words.isNotEmpty;
  }

  /// Get all available letters in this category
  List<String> get availableLetters {
    return wordsByLetter.keys.where((k) => wordsByLetter[k]!.isNotEmpty).toList()..sort();
  }
}

/// Service for loading and managing game categories
class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  final List<Category> _categories = [];
  bool _initialized = false;
  final _random = Random();

  /// Whether the service has been initialized
  bool get isInitialized => _initialized;

  /// All available categories
  List<Category> get categories => List.unmodifiable(_categories);

  /// Total number of categories
  int get categoryCount => _categories.length;

  /// List of category file names (without path)
  static const List<String> _categoryFiles = [
    '01_animals.json',
    '02_countries.json',
    '03_movies.json',
    '04_food_and_drink.json',
    '05_sports.json',
    '06_occupations.json',
    '07_cities.json',
    '08_tv_shows.json',
    '09_famous_people.json',
    '10_musical_instruments.json',
    '11_fruits_and_vegetables.json',
    '12_landmarks.json',
    '13_clothing.json',
    '14_technology.json',
    '15_colors.json',
    '16_book_titles.json',
    '17_holidays.json',
    '18_body_parts.json',
    '19_weather.json',
    '20_dance_styles.json',
    '21_planets_and_space.json',
    '22_mythical_creatures.json',
    '23_desserts.json',
    '24_flowers.json',
    '25_video_games.json',
    '26_fairy_tales.json',
    '27_kitchen_items.json',
    '28_music_genres.json',
    '29_transportation.json',
    '30_hobbies.json',
    '31_emotions.json',
    '32_superheroes.json',
    '33_breakfast_foods.json',
    '34_furniture.json',
    '35_board_games.json',
    '36_ocean_life.json',
    '37_carnival_and_circus.json',
    '38_art_styles.json',
    '39_natural_disasters.json',
    '40_camping_and_outdoors.json',
    '41_famous_brands.json',
    '42_school_subjects.json',
    '43_wedding_and_romance.json',
    '44_dog_breeds.json',
    '45_cat_breeds.json',
    '46_office_items.json',
    '47_beverages.json',
    '48_toys_and_games.json',
    '49_disney_characters.json',
    '50_around_the_house.json',
  ];

  /// Initialize and load categories from assets
  Future<void> init() async {
    if (_initialized) return;

    try {
      for (final fileName in _categoryFiles) {
        try {
          final jsonString = await rootBundle.loadString(
            'assets/data/categories/$fileName',
          );
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          final category = Category.fromJson(jsonData);
          _categories.add(category);
        } catch (e) {
          debugPrint('CategoryService: Failed to load $fileName - $e');
        }
      }

      _initialized = true;
      debugPrint('CategoryService: Loaded ${_categories.length} categories');
    } catch (e) {
      debugPrint('CategoryService: Failed to initialize - $e');
      _initialized = true;
    }
  }

  /// Get a category by ID
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get a category by name
  Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get a random category
  Category? getRandomCategory() {
    if (_categories.isEmpty) return null;
    return _categories[_random.nextInt(_categories.length)];
  }

  /// Get a random category that has words for a specific letter
  Category? getRandomCategoryForLetter(String letter) {
    final validCategories = _categories
        .where((c) => c.hasWordsForLetter(letter))
        .toList();
    if (validCategories.isEmpty) return null;
    return validCategories[_random.nextInt(validCategories.length)];
  }

  /// Get a random word from a specific category for a specific letter
  String? getRandomWordFromCategory(int categoryId, String letter) {
    final category = getCategoryById(categoryId);
    if (category == null) return null;

    final words = category.getWordsForLetter(letter);
    if (words.isEmpty) return null;

    return words[_random.nextInt(words.length)];
  }

  /// Get categories that have words starting with a specific letter
  List<Category> getCategoriesWithLetter(String letter) {
    return _categories.where((c) => c.hasWordsForLetter(letter)).toList();
  }

  /// Get all words from a category that start with a specific letter
  List<String> getWordsStartingWith(int categoryId, String letter) {
    final category = getCategoryById(categoryId);
    if (category == null) return [];
    return category.getWordsForLetter(letter);
  }

  /// Get a random word and category for a specific letter
  ({Category category, String word})? getRandomWordForLetter(String letter) {
    final validCategories = getCategoriesWithLetter(letter);
    if (validCategories.isEmpty) return null;

    final category = validCategories[_random.nextInt(validCategories.length)];
    final words = category.getWordsForLetter(letter);
    if (words.isEmpty) return null;

    final word = words[_random.nextInt(words.length)];
    return (category: category, word: word);
  }

  /// Get categories for a letter, weighted by difficulty based on game round
  /// Higher rounds increase likelihood of harder categories
  /// Round 1-5: favor easy (1-4), Round 6-15: favor medium (3-7), Round 16-25: favor hard (6-10)
  List<Category> getCategoriesForLetterWeightedByRound(String letter, int round) {
    final validCategories = getCategoriesWithLetter(letter);
    if (validCategories.isEmpty) return [];

    // Calculate target difficulty based on round (1-25 rounds)
    // Round 1 -> target ~2, Round 25 -> target ~9
    final progress = ((round - 1) / 24).clamp(0.0, 1.0);
    final targetDifficulty = 2 + (progress * 7); // Range 2-9

    // Weight categories: closer to target difficulty = higher weight
    // Using inverse distance with a minimum weight to avoid 0
    final weightedList = <Category>[];

    for (final category in validCategories) {
      final distance = (category.difficulty - targetDifficulty).abs();
      // Weight formula: higher weight for closer to target
      // Max distance is ~8, so weight ranges from 1 (far) to 9 (exact match)
      final weight = (9 - distance).clamp(1.0, 9.0).round();

      // Add category multiple times based on weight
      for (var i = 0; i < weight; i++) {
        weightedList.add(category);
      }
    }

    // Shuffle the weighted list
    weightedList.shuffle(_random);
    return weightedList;
  }

  /// Get N random categories for a letter, weighted by difficulty
  List<Category> getNRandomCategoriesWeighted(String letter, int round, int count) {
    final weightedCategories = getCategoriesForLetterWeightedByRound(letter, round);
    if (weightedCategories.isEmpty) return [];

    // Get unique categories up to count
    final selectedCategories = <Category>[];
    final selectedIds = <int>{};

    for (final category in weightedCategories) {
      if (!selectedIds.contains(category.id)) {
        selectedIds.add(category.id);
        selectedCategories.add(category);
        if (selectedCategories.length >= count) break;
      }
    }

    return selectedCategories;
  }
}
