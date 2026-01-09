import 'package:flutter/material.dart';
import 'package:constellation_app/main_menu/cubit/cubit.dart';
import 'package:constellation_app/main_menu/widgets/main_menu_body.dart';

/// {@template main_menu_page}
/// A description for MainMenuPage
/// {@endtemplate}
class MainMenuPage extends StatelessWidget {
  /// {@macro main_menu_page}
  const MainMenuPage({super.key});

  /// The static route for MainMenuPage
  static Route<dynamic> route() {
    return MaterialPageRoute<dynamic>(builder: (_) => const MainMenuPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MainMenuCubit(),
      child: const Scaffold(
        body: MainMenuView(),
      ),
    );
  }    
}

/// {@template main_menu_view}
/// Displays the Body of MainMenuView
/// {@endtemplate}
class MainMenuView extends StatelessWidget {
  /// {@macro main_menu_view}
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainMenuBody();
  }
}
