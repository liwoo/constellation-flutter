import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// {@template splash_page}
/// Splash screen that shows after the system app icon splash.
/// Displays the app logo and transitions to the main menu.
/// {@endtemplate}
class SplashPage extends StatefulWidget {
  /// {@macro splash_page}
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Start the animation immediately
    _animationController.forward();

    // Show splash for 2.5 seconds total
    await Future.delayed(const Duration(milliseconds: 2500));

    // Navigate to main menu
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Image.asset(
                      'assets/logos/afri_games.png',
                      width: 200,
                      height: 200,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
