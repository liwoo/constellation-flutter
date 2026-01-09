// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/main_menu/cubit/cubit.dart';

void main() {
  group('MainMenuState', () {
    test('supports value equality', () {
      expect(
        MainMenuState(),
        equals(
          const MainMenuState(),
        ),
      );
    });

    group('constructor', () {
      test('can be instantiated', () {
        expect(
          const MainMenuState(),
          isNotNull,
        );
      });
    });

    group('copyWith', () {
      test(
        'copies correctly '
        'when no argument specified',
        () {
          const mainMenuState = MainMenuState(
            customProperty: 'My property',
          );
          expect(
            mainMenuState.copyWith(),
            equals(mainMenuState),
          );
        },
      );

      test(
        'copies correctly '
        'when all arguments specified',
        () {
          const mainMenuState = MainMenuState(
            customProperty: 'My property',
          );
          final otherMainMenuState = MainMenuState(
            customProperty: 'My property 2',
          );
          expect(mainMenuState, isNot(equals(otherMainMenuState)));

          expect(
            mainMenuState.copyWith(
              customProperty: otherMainMenuState.customProperty,
            ),
            equals(otherMainMenuState),
          );
        },
      );
    });
  });
}
