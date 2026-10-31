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

  test('normal difficulty filtering resumes after round 6', () {
    final names = CategoryService.instance
        .getCategoriesForLetterWeightedByRound('A', 7)
        .map((category) => category.name)
        .toSet();

    expect(names, isNot(contains('Cities')));
    expect(names, isNot(contains('Occupations')));
  });
}
