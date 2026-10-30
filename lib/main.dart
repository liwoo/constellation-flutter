import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:constellation_app/app/router.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/mobile_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - app works without it)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize services
  await AnalyticsService.instance.init();
  await AudioService.instance.init();
  // Decode sounds + start music in the background so launch isn't delayed.
  unawaited(AudioService.instance.preloadSounds());
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
      // Laptops and large screens get a centered phone-sized frame
      builder: (context, child) => MobileFrame(child: child ?? const SizedBox.shrink()),
    );
  }
}
