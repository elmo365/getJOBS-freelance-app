import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';

/// Displays a user's overall rating prominently on their profile
class UserRatingCard extends StatelessWidget {
  final String userId;
  final String userType; // 'jobSeeker' or 'company'

  const UserRatingCard({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppCard(
            padding: AppDesignSystem.paddingL,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final avgRating = (userData['avgRating'] as num?)?.toDouble() ?? 5.0;
        final ratingCount = (userData['ratingCount'] as int?) ?? 0;

        final stars = _buildStarRow(avgRating, colorScheme);
        final ratingColor = _getRatingColor(colorScheme, avgRating);

        return AppCard(
          variant: SurfaceVariant.elevated,
          padding: AppDesignSystem.paddingL,
          child: Row(
            children: [
              // Left side: Rating badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ratingColor.withValues(alpha: 0.2),
                      ratingColor.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: ratingColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: ratingColor,
                      ),
                    ),
                    Wrap(
                      spacing: 2,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < avgRating.round()
                              ? Icons.star
                              : Icons.star_outline,
                          size: 12,
                          color: ratingColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceL),
              // Right side: Rating details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Rating',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Row(
                      children: [
                        ...stars,
                      ],
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Text(
                      'Based on $ratingCount ${ratingCount == 1 ? 'review' : 'reviews'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (ratingCount == 0) ...[
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                      Text(
                        '(Default rating)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildStarRow(double rating, ColorScheme colorScheme) {
    final fullStars = rating.toInt();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return List.generate(5, (index) {
      if (index < fullStars) {
        return Icon(Icons.star, size: 16, color: Colors.amber);
      } else if (index == fullStars && hasHalfStar) {
        return Icon(Icons.star_half, size: 16, color: Colors.amber);
      } else {
        return Icon(Icons.star_outline, size: 16, color: Colors.amber);
      }
    }).map((icon) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: icon,
        )).toList();
  }

  Color _getRatingColor(ColorScheme colorScheme, double rating) {
    if (rating >= 4.5) return colorScheme.primary;
    if (rating >= 4.0) return const Color(0xFF4CAF50);
    if (rating >= 3.0) return const Color(0xFFFFC107);
    if (rating >= 2.0) return const Color(0xFFFF9800);
    return colorScheme.error;
  }
}
