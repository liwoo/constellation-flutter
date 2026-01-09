// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:constellation_app/game/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GamePage', () {
    group('route', () {
      test('is routable', () {
        expect(GamePage.route(), isA<MaterialPageRoute>());
      });
    });

    testWidgets('renders GameView', (tester) async {
      await tester.pumpWidget(MaterialApp(home: GamePage()));
      expect(find.byType(GameView), findsOneWidget);
    });
  });
}
