import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:constellation_app/main_menu/cubit/cubit.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// {@template main_menu_body}
/// Body of the MainMenuPage.
///
/// Main menu screen with game title, decorative stars, and navigation buttons
/// {@endtemplate}
class MainMenuBody extends StatelessWidget {
  /// {@macro main_menu_body}
  const MainMenuBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainMenuCubit, MainMenuState>(
      builder: (context, state) {
        return GradientBackground(
          child: Stack(
            children: [
              // Star decorations
              const Positioned.fill(
                child: StarDecoration(starCount: 100, starSize: 3.0),
              ),

              // Content
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Game Title
                        Text(
                          'CONSTELLATION',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    color: AppColors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Subtitle
                        Text(
                          'WORD GAME',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 3.0,
                                  ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(),

                        // Decorative stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              child: Icon(
                                Icons.star,
                                color: AppColors.accentGold,
                                size: 32,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Start Game button
                        GameButton(
                          text: 'START GAME',
                          onPressed: () => context.go('/game'),
                          isPrimary: true,
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Settings button
                        GameButton(
                          text: 'SETTINGS',
                          onPressed: () => context.go('/settings'),
                          isPrimary: false,
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
