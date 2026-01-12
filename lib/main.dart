import 'package:flutter/material.dart';
import 'package:constellation_app/app/router.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await AudioService.instance.init();
  await AudioService.instance.preloadSounds();
  await HapticService.instance.init();
  await CategoryService.instance.init();

  runApp(const ConstellationApp());
}

/// {@template constellation_app}
/// The root widget of the Constellation word game application.
/// {@endtemplate}
class ConstellationApp extends StatelessWidget {
  /// {@macro constellation_app}
  const ConstellationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter();

    return MaterialApp.router(
      title: 'Constellation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
