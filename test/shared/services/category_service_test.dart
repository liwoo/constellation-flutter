import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/shared/services/category_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final familiarCategories = {
    'Animals',
    'Food & Drink',
    'Countries',
    'Cities',
    'Around The House',
    'Kitchen Items',
    'Clothing',
    'Occupations',
    'Transportation',
    'Cars',
    'Popular Names',
  };

  setUpAll(CategoryService.instance.init);

  test('rounds 1-6 heavily weight familiar categories', () {
    for (final round in [1, 6]) {
      final weighted = CategoryService.instance
          .getCategoriesForLetterWeightedByRound('A', round);
      final names = weighted.map((category) => category.name).toSet();
      final familiarEntries = weighted
          .where((category) => familiarCategories.contains(category.name))
          .length;
      final otherEntries = weighted.length - familiarEntries;

      expect(names, containsAll(familiarCategories));
      expect(familiarEntries, greaterThan(otherEntries * 10));
    }
  });

  group('added categories', () {
    const names = [
      'Bible Characters',
      'Historical Leaders',
      'African Tribes & Languages',
      'School Stuff',
      'Hollywood Stars',
      'Authors',
    ];

    test('load with a deep word list', () {
      for (final name in names) {
        final category = CategoryService.instance.getCategoryByName(name);
        expect(category, isNotNull, reason: name);
        expect(category!.allWords.length, greaterThan(300), reason: name);
        expect(category.availableLetters.length, greaterThanOrEqualTo(25),
            reason: name);
      }
    });

    test('every answer is spellable on the board and filed by its letter',
        () {
      final spellable = RegExp(r'^[A-Z]+( [A-Z]+)*$');
      for (final name in names) {
        final category = CategoryService.instance.getCategoryByName(name)!;
        for (final entry in category.wordsByLetter.entries) {
          for (final word in entry.value) {
            expect(word, matches(spellable), reason: '$name: $word');
            expect(word[0], entry.key, reason: '$name: $word');
          }
        }
      }
    });

    test('surnames and short forms are answers on their own letter', () {
      final dictionary = CategoryDictionary.instance;
      expect(dictionary.isValidWord('MANDELA', 'Historical Leaders', 'M'),
          isTrue);
      expect(dictionary.isValidWord('NELSON', 'Historical Leaders', 'N'),
          isTrue);
      expect(dictionary.isValidWord('KAMUZU', 'Historical Leaders', 'K'),
          isTrue);
      expect(dictionary.isValidWord('CHICHEWA', 'African Tribes & Languages',
          'C'), isTrue);
      expect(dictionary.isValidWord('ZULU', 'African Tribes & Languages', 'Z'),
          isTrue);
      expect(dictionary.isValidWord('MOSES', 'Bible Characters', 'M'), isTrue);
      expect(dictionary.isValidWord('ISCARIOT', 'Bible Characters', 'I'),
          isTrue);
      expect(dictionary.isValidWord('HANKS', 'Hollywood Stars', 'H'), isTrue);
      expect(dictionary.isValidWord('ACHEBE', 'Authors', 'A'), isTrue);
      expect(dictionary.isValidWord('MAPANJE', 'Authors', 'M'), isTrue);
    });
  });

  test('normal difficulty filtering resumes after round 6', () {
    final names = CategoryService.instance
        .getCategoriesForLetterWeightedByRound('A', 7)
        .map((category) => category.name)
        .toSet();

    expect(names, isNot(contains('Cities')));
    expect(names, isNot(contains('Occupations')));
  });
}
