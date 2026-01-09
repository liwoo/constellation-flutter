import 'package:flutter/material.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/theme/theme.dart';

/// Yellow/orange gradient banner for category display
/// Matches reference: rounded top corners, flat bottom with angled edges,
/// small black pill at top center with "CATEGORY" text
class CategoryBanner extends StatelessWidget {
  const CategoryBanner({
    super.key,
    required this.category,
  });

  final String category;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Main banner with gradient
        Container(
          margin: const EdgeInsets.only(top: 10), // Space for pill
          child: ClipPath(
            clipper: _BannerClipper(),
            child: Container(
              padding: const EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentYellow,
                    AppColors.accentOrange,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Text(
                category.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Category pill at top center
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.black.withAlpha(220),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'CATEGORY',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom clipper for banner shape:
/// - Rounded top-left and top-right corners
/// - Angled/pointed bottom-left and bottom-right (ribbon style)
class _BannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const topRadius = 16.0;
    const bottomPointHeight = 10.0; // How much the bottom points extend

    // Start at top-left corner (after radius)
    path.moveTo(topRadius, 0);

    // Top edge
    path.lineTo(size.width - topRadius, 0);

    // Top-right rounded corner
    path.arcToPoint(
      Offset(size.width, topRadius),
      radius: const Radius.circular(topRadius),
    );

    // Right edge down to bottom point
    path.lineTo(size.width, size.height - bottomPointHeight);

    // Bottom-right angled point going inward
    path.lineTo(size.width - 15, size.height);

    // Bottom edge (flat)
    path.lineTo(15, size.height);

    // Bottom-left angled point going inward
    path.lineTo(0, size.height - bottomPointHeight);

    // Left edge up
    path.lineTo(0, topRadius);

    // Top-left rounded corner
    path.arcToPoint(
      Offset(topRadius, 0),
      radius: const Radius.circular(topRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
