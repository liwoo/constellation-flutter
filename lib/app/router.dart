import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:constellation_app/main_menu/main_menu.dart';
import 'package:constellation_app/game/game.dart';
import 'package:constellation_app/settings/settings.dart';

/// App router configuration using GoRouter
class AppRouter {
  const AppRouter._();

  /// Creates and configures the GoRouter instance
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      routes: [
        // Main Menu route
        GoRoute(
          path: '/',
          name: 'main-menu',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const MainMenuPage(),
          ),
        ),

        // Game route
        GoRoute(
          path: '/game',
          name: 'game',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const GamePage(),
          ),
        ),

        // Settings route
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const SettingsPage(),
          ),
        ),
      ],

      // Error page
      errorPageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: Scaffold(
          body: Center(
            child: Text('Error: ${state.error}'),
          ),
        ),
      ),
    );
  }
}
