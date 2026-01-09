// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/game/cubit/cubit.dart';

void main() {
  group('GameState', () {
    test('supports value equality', () {
      expect(
        GameState(),
        equals(
          const GameState(),
        ),
      );
    });

    group('constructor', () {
      test('can be instantiated', () {
        expect(
          const GameState(),
          isNotNull,
        );
      });
    });

    group('copyWith', () {
      test(
        'copies correctly '
        'when no argument specified',
        () {
          const gameState = GameState(
            customProperty: 'My property',
          );
          expect(
            gameState.copyWith(),
            equals(gameState),
          );
        },
      );

      test(
        'copies correctly '
        'when all arguments specified',
        () {
          const gameState = GameState(
            customProperty: 'My property',
          );
          final otherGameState = GameState(
            customProperty: 'My property 2',
          );
          expect(gameState, isNot(equals(otherGameState)));

          expect(
            gameState.copyWith(
              customProperty: otherGameState.customProperty,
            ),
            equals(otherGameState),
          );
        },
      );
    });
  });
}
