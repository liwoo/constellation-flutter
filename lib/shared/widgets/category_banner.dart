import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Yellow/orange gradient banner for category display
class CategoryBanner extends StatelessWidget {
  const CategoryBanner({
    super.key,
    required this.category,
    this.starCount = 3,
  });

  final String category;
  final int starCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.accentYellow,
                AppColors.accentOrange,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: .circular(AppBorderRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: .min,
            children: [
              Text(
                'CATEGORY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.black,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                category.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.black,
                      fontWeight: .bold,
                      letterSpacing: 1.0,
                    ),
                textAlign: .center,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Star rating
        Row(
          mainAxisSize: .min,
          children: List.generate(
            AppConstants.maxDifficulty,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(
                index < starCount ? Icons.star : Icons.star_border,
                color: AppColors.accentGold,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
