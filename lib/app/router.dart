import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:constellation_app/splash/splash.dart';
import 'package:constellation_app/main_menu/main_menu.dart';
import 'package:constellation_app/game/game.dart';
import 'package:constellation_app/practice/practice.dart';
import 'package:constellation_app/settings/settings.dart';

/// App router configuration using GoRouter
class AppRouter {
  const AppRouter._();

  /// Creates and configures the GoRouter instance
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: true,
      routes: [
        // Splash Screen route
        GoRoute(
          path: '/splash',
          name: 'splash',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const SplashPage()),
        ),

        // Main Menu route
        GoRoute(
          path: '/',
          name: 'main-menu',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const MainMenuPage()),
        ),

        // Game route
        GoRoute(
          path: '/game',
          name: 'game',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const GamePage()),
        ),

        // Alpha Quest route
        GoRoute(
          path: '/alpha-quest',
          name: 'alpha-quest',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const AlphaQuestPage()),
        ),

        // Settings route
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const SettingsPage()),
        ),

        // Practice route
        GoRoute(
          path: '/practice',
          name: 'practice',
          pageBuilder: (context, state) =>
              MaterialPage(key: state.pageKey, child: const PracticePage()),
        ),
      ],

      // Error page
      errorPageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(body: Center(child: Text('Error: ${state.error}'))),
      ),
    );
  }
}
