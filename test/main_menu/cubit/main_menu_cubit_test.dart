// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/main_menu/cubit/cubit.dart';

void main() {
  group('MainMenuCubit', () {
    group('constructor', () {
      test('can be instantiated', () {
        expect(
          MainMenuCubit(),
          isNotNull,
        );
      });
    });

    test('initial state has default value for customProperty', () {
      final mainMenuCubit = MainMenuCubit();
      expect(mainMenuCubit.state.customProperty, equals('Default Value'));
    });

    blocTest<MainMenuCubit, MainMenuState>(
      'yourCustomFunction emits nothing',
      build: MainMenuCubit.new,
      act: (cubit) => cubit.yourCustomFunction(),
      expect: () => <MainMenuState>[],
    );
  });
}
