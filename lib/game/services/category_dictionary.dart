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
  /// Supports partial name matching - user can type first name, last name, or full name
  /// e.g., "FERDINAND", "RIO", or "RIO FERDINAND" all match "RIO FERDINAND"
  bool isValidWord(String word, String category, String startingLetter) {
    final upperWord = word.toUpperCase().replaceAll(' ', '');
    final upperLetter = startingLetter.toUpperCase();

    // Find the category by name
    final categoryObj = _categoryService.getCategoryByName(category);
    if (categoryObj == null) return false;

    // Get words for this letter in this category
    final words = categoryObj.getWordsForLetter(upperLetter);

    // Check if the word matches any word or part of a word in the category
    for (final validWord in words) {
      final upperValidWord = validWord.toUpperCase();
      final upperValidWordNoSpaces = upperValidWord.replaceAll(' ', '');

      // Exact match (with or without spaces)
      if (upperValidWordNoSpaces == upperWord) return true;

      // Match any individual part of a multi-word entry (for names like "RIO FERDINAND")
      // This allows matching "FERDINAND" or "RIO" separately
      final parts = upperValidWord.split(' ');
      if (parts.length > 1) {
        // Check each individual part
        if (parts.any((part) => part == upperWord)) return true;

        // Also check combinations (e.g., "MICHAELJORDAN" matching "MICHAEL JORDAN")
        // Already handled by upperValidWordNoSpaces check above
      }
    }

    return false;
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
  /// Supports partial name matching - allows paths to any part of multi-word entries
  bool isValidPrefix(String prefix, String category, String startingLetter) {
    if (prefix.isEmpty) return true;

    final upperPrefix = prefix.toUpperCase().replaceAll(' ', '');
    final upperLetter = startingLetter.toUpperCase();

    // Get all valid words for this letter/category
    final words = getWordsForCategoryAndLetter(category, upperLetter);
    if (words.isEmpty) return false;

    // Check if any word or word part starts with this prefix
    for (final word in words) {
      final upperWord = word.toUpperCase();
      final upperWordNoSpaces = upperWord.replaceAll(' ', '');

      // Check if the full word/phrase starts with prefix (with or without spaces)
      if (upperWordNoSpaces.startsWith(upperPrefix)) return true;

      // For multi-word entries, also check if any individual part starts with prefix
      // This allows typing "FER" to match "FERDINAND" in "RIO FERDINAND"
      final parts = upperWord.split(' ');
      if (parts.length > 1) {
        if (parts.any((part) => part.startsWith(upperPrefix))) return true;
      }
    }

    return false;
  }
}
