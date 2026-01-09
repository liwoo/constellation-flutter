// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:constellation_app/main_menu/main_menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainMenuPage', () {
    group('route', () {
      test('is routable', () {
        expect(MainMenuPage.route(), isA<MaterialPageRoute>());
      });
    });

    testWidgets('renders MainMenuView', (tester) async {
      await tester.pumpWidget(MaterialApp(home: MainMenuPage()));
      expect(find.byType(MainMenuView), findsOneWidget);
    });
  });
}
