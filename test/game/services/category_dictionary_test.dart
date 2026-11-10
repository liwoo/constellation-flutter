import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/shared/services/category_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await CategoryService.instance.init();
  });

  final dictionary = CategoryDictionary.instance;

  group('CategoryDictionary', () {
    test('a whole entry counts, with or without its spaces', () {
      expect(dictionary.isValidWord('JOGGER PANTS', 'CLOTHING', 'J'), isTrue);
      expect(dictionary.isValidWord('JOGGERPANTS', 'CLOTHING', 'J'), isTrue);
    });

    test('part of an entry counts only if it starts with the letter', () {
      expect(dictionary.isValidWord('RIO', 'FAMOUS PEOPLE', 'R'), isTrue);
      expect(dictionary.isValidWord('FERDINAND', 'FAMOUS PEOPLE', 'R'), isFalse);
      expect(dictionary.isValidWord('PANTS', 'CLOTHING', 'J'), isFalse);
    });

    test('prefixes follow the same letter rule', () {
      expect(dictionary.isValidPrefix('JOG', 'CLOTHING', 'J'), isTrue);
      expect(dictionary.isValidPrefix('PAN', 'CLOTHING', 'J'), isFalse);
    });
  });
}
