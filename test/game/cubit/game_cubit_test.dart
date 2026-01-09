// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/game/cubit/cubit.dart';

void main() {
  group('GameCubit', () {
    group('constructor', () {
      test('can be instantiated', () {
        expect(
          GameCubit(),
          isNotNull,
        );
      });
    });

    test('initial state has default value for customProperty', () {
      final gameCubit = GameCubit();
      expect(gameCubit.state.customProperty, equals('Default Value'));
    });

    blocTest<GameCubit, GameState>(
      'yourCustomFunction emits nothing',
      build: GameCubit.new,
      act: (cubit) => cubit.yourCustomFunction(),
      expect: () => <GameState>[],
    );
  });
}
