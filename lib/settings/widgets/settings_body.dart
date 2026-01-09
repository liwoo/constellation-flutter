import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:constellation_app/settings/cubit/cubit.dart';
import 'package:constellation_app/shared/widgets/widgets.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// {@template settings_body}
/// Body of the SettingsPage.
///
/// Settings screen with sound, music toggles and timer duration selector
/// {@endtemplate}
class SettingsBody extends StatefulWidget {
  /// {@macro settings_body}
  const SettingsBody({super.key});

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  int _selectedTimer = AppConstants.timerMedium;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return GradientBackground(
          child: Stack(
            children: [
              // Star decorations
              const Positioned.fill(
                child: StarDecoration(starCount: 70, starSize: 2.5),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Top bar with back button
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.white,
                              size: 28,
                            ),
                            onPressed: () => context.go('/'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'SETTINGS',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Settings content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sound toggle
                              _buildSettingCard(
                                context: context,
                                icon: Icons.volume_up,
                                title: 'Sound Effects',
                                subtitle: 'Enable game sound effects',
                                trailing: PlatformSwitch(
                                  value: _soundEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _soundEnabled = value;
                                    });
                                  },
                                  material: (_, __) => MaterialSwitchData(
                                    activeColor: AppColors.accentGold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Music toggle
                              _buildSettingCard(
                                context: context,
                                icon: Icons.music_note,
                                title: 'Background Music',
                                subtitle: 'Play background music',
                                trailing: PlatformSwitch(
                                  value: _musicEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _musicEnabled = value;
                                    });
                                  },
                                  material: (_, __) => MaterialSwitchData(
                                    activeColor: AppColors.accentGold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxl),

                              // Timer duration section
                              Text(
                                'TIMER DURATION',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                              ),

                              const SizedBox(height: AppSpacing.md),

                              // Timer options
                              ...AppConstants.availableTimers.map(
                                (timer) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _buildTimerOption(
                                    context: context,
                                    duration: timer,
                                    isSelected: _selectedTimer == timer,
                                    onTap: () {
                                      setState(() {
                                        _selectedTimer = timer;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xxl),

                              // Back button
                              GameButton(
                                text: 'BACK TO MENU',
                                onPressed: () => context.go('/'),
                                isPrimary: true,
                              ),

                              const SizedBox(height: AppSpacing.lg),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.accentGold,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildTimerOption({
    required BuildContext context,
    required int duration,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    final displayText = seconds > 0 ? '$minutes:${seconds}0' : '$minutes:00';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold.withOpacity(0.2)
              : AppColors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGold
                : AppColors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer,
              color: isSelected ? AppColors.accentGold : AppColors.white,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                displayText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppColors.accentGold : AppColors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.accentGold,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
