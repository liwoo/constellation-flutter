import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:constellation_app/app/router.dart';
import 'package:constellation_app/firebase_options.dart';
import 'package:constellation_app/shared/services/services.dart';
import 'package:constellation_app/shared/theme/theme.dart';
import 'package:constellation_app/shared/widgets/mobile_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - app works without it)
  try {
    if (_useFirebaseEmulator) {
      await _connectToEmulators();
    } else {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
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

/// Run against the local Firebase emulators (auth + Realtime Database) for
/// trying multiplayer without a real project:
///   firebase emulators:start --only auth,database --project demo-constellation
///   flutter run --dart-define=USE_FIREBASE_EMULATOR=true
const _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
const _authEmulatorPort = int.fromEnvironment('AUTH_EMULATOR_PORT', defaultValue: 9099);
const _databaseEmulatorPort = int.fromEnvironment('DATABASE_EMULATOR_PORT', defaultValue: 9000);

Future<void> _connectToEmulators() async {
  // Android emulators reach the host machine on 10.0.2.2
  final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : '127.0.0.1';
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'demo-key',
      appId: '1:1:web:1',
      messagingSenderId: '1',
      projectId: 'demo-constellation',
      databaseURL: 'http://$host:$_databaseEmulatorPort?ns=demo-constellation',
    ),
  );
  await FirebaseAuth.instance.useAuthEmulator(host, _authEmulatorPort);
  FirebaseDatabase.instance.useDatabaseEmulator(host, _databaseEmulatorPort);
  debugPrint('Firebase: using local emulators on $host');
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
