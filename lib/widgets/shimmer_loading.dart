import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_design_system.dart';

/// Shimmer loading effect for better UX
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // Subtle shimmer on white surfaces (avoid grey blocks).
      // Performance optimization: Use theme-aware colors
      baseColor: Theme.of(context)
          .colorScheme
          .surfaceContainerLowest
          .withValues(alpha: 0.7),
      highlightColor: Theme.of(context)
          .colorScheme
          .surfaceContainerLowest
          .withValues(alpha: 0.3),
      period: const Duration(milliseconds: 1500), // Smoother animation
      child: child,
    );
  }
}

/// Shimmer placeholder for cards
class ShimmerCard extends StatelessWidget {
  final double? height;
  final double? width;

  const ShimmerCard({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height ?? 120,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for list items
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      child: _ShimmerListItemContent(),
    );
  }
}

/// Extracted content widget for better performance (avoids recreation)
class _ShimmerListItemContent extends StatelessWidget {
  const _ShimmerListItemContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spaceM,
        vertical: AppDesignSystem.spaceS,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spaceM),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusS),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusS),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder for job cards
class ShimmerJobCard extends StatelessWidget {
  const ShimmerJobCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spaceM,
          vertical: AppDesignSystem.spaceS,
        ),
        padding: const EdgeInsets.all(AppDesignSystem.spaceM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppDesignSystem.backgroundLight,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusS),
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 18,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppDesignSystem.backgroundLight,
                          borderRadius:
                              BorderRadius.circular(AppDesignSystem.radiusS),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppDesignSystem.backgroundLight,
                          borderRadius:
                              BorderRadius.circular(AppDesignSystem.radiusS),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDesignSystem.spaceM),
            // Description
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundLight,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 200,
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundLight,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
              ),
            ),
            const SizedBox(height: AppDesignSystem.spaceM),
            // Tags
            Row(
              children: [
                Container(
                  height: 24,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppDesignSystem.backgroundLight,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusCircular),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 24,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppDesignSystem.backgroundLight,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusCircular),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer grid for loading multiple items
class ShimmerGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppDesignSystem.spaceM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDesignSystem.spaceM,
        mainAxisSpacing: AppDesignSystem.spaceM,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }
}

/// Shimmer list for loading multiple items
class ShimmerList extends StatelessWidget {
  final int itemCount;

  const ShimmerList({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerListItem(),
    );
  }
}
