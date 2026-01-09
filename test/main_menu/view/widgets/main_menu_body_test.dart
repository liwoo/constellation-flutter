// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:constellation_app/main_menu/main_menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainMenuBody', () {
    testWidgets('renders Text', (tester) async { 
      await tester.pumpWidget(
        BlocProvider(
          create: (context) => MainMenuCubit(),
          child: MaterialApp(home: MainMenuBody()),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });
}
