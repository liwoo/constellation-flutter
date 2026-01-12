import 'dart:math';

import 'package:constellation_app/shared/services/category_service.dart';

/// Category dictionary service for Alpha Quest game mode
/// Delegates to CategoryService which loads categories from JSON files
class CategoryDictionary {
  CategoryDictionary._();

  static final CategoryDictionary instance = CategoryDictionary._();
  final _random = Random();

  final CategoryService _categoryService = CategoryService.instance;

  /// All available category names (uppercase for display)
  static List<String> get categories {
    return CategoryService.instance.categories
        .map((c) => c.name.toUpperCase())
        .toList();
  }

  /// Get a random category name
  String getRandomCategory() {
    final category = _categoryService.getRandomCategory();
    return category?.name.toUpperCase() ?? 'ANIMALS';
  }

  /// Get a random category that has words for the given letter
  String? getRandomCategoryForLetter(String letter) {
    final category = _categoryService.getRandomCategoryForLetter(letter);
    return category?.name.toUpperCase();
  }

  /// Check if a word is valid for the given category and starting letter
  bool isValidWord(String word, String category, String startingLetter) {
    final upperWord = word.toUpperCase();
    final upperLetter = startingLetter.toUpperCase();

    // Check if word starts with the required letter
    if (!upperWord.startsWith(upperLetter)) return false;

    // Find the category by name
    final categoryObj = _categoryService.getCategoryByName(category);
    if (categoryObj == null) return false;

    // Get words for this letter in this category
    final words = categoryObj.getWordsForLetter(upperLetter);

    // Check if the word matches any word in the category
    // Use contains check to handle multi-word answers
    return words.any((validWord) => validWord.toUpperCase() == upperWord);
  }

  /// Get all valid words for a category and letter
  List<String> getWordsForCategoryAndLetter(String category, String letter) {
    final categoryObj = _categoryService.getCategoryByName(category);
    if (categoryObj == null) return [];
    return categoryObj.getWordsForLetter(letter.toUpperCase());
  }

  /// Check if a category has any words for the given letter
  bool categoryHasWordsForLetter(String category, String letter) {
    final categoryObj = _categoryService.getCategoryByName(category);
    if (categoryObj == null) return false;
    return categoryObj.hasWordsForLetter(letter.toUpperCase());
  }

  /// Get a random word from the category for the given letter
  /// Used for hints
  String? getRandomWord(String category, String letter) {
    final words = getWordsForCategoryAndLetter(category, letter);
    if (words.isEmpty) return null;
    return words[_random.nextInt(words.length)];
  }

  /// Check if a prefix could lead to a valid word in the category
  /// This enables "smart connections" - only allow letter paths that could form valid words
  /// For example, if no words in BRANDS start with "BR", B->R connection is blocked
  bool isValidPrefix(String prefix, String category, String startingLetter) {
    if (prefix.isEmpty) return true;

    final upperPrefix = prefix.toUpperCase();
    final upperLetter = startingLetter.toUpperCase();

    // Prefix must start with the required letter
    if (!upperPrefix.startsWith(upperLetter)) return false;

    // Get all valid words for this letter/category
    final words = getWordsForCategoryAndLetter(category, upperLetter);
    if (words.isEmpty) return false;

    // Check if any word starts with this prefix
    // Handle multi-word answers by checking each word part and full phrase
    for (final word in words) {
      final upperWord = word.toUpperCase();
      // Check if the full word/phrase starts with prefix
      if (upperWord.startsWith(upperPrefix)) return true;
      // Also check without spaces (for continuous letter chains)
      if (upperWord.replaceAll(' ', '').startsWith(upperPrefix.replaceAll(' ', ''))) return true;
    }

    return false;
  }
}
