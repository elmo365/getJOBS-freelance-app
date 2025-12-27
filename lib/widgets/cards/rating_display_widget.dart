import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/models/rating_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/app_theme.dart';

/// Widget to display user ratings and reviews
/// Shows average rating, star count, and list of individual ratings
class RatingDisplayWidget extends StatelessWidget {
  final String userId;
  final String userType; // 'jobSeeker' or 'company'
  final bool compact; // If true, show minimal version (just stars and average)
  final VoidCallback? onViewAllPressed;

  const RatingDisplayWidget({
    super.key,
    required this.userId,
    required this.userType,
    this.compact = false,
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .where('ratedUserType', isEqualTo: userType)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        if (snapshot.hasError) {
          return _buildErrorState(context);
        }

        final ratings = snapshot.data?.docs ?? [];

        if (ratings.isEmpty) {
          return _buildEmptyState(context);
        }

        // Calculate average rating
        final ratingModels = ratings
            .map((doc) => RatingModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();

        final avgRating = ratingModels.isEmpty
            ? 0.0
            : ratingModels.fold<double>(0.0, (acc, r) => acc + r.rating) /
                ratingModels.length;
        final totalRatings = ratingModels.length;

        if (compact) {
          return _buildCompactRating(context, avgRating, totalRatings);
        }

        return _buildExpandedRating(context, avgRating, totalRatings, ratingModels);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spaceM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: const Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spaceM),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Text(
        'Unable to load ratings',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spaceM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Center(
        child: Text(
          'No ratings yet',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRating(
    BuildContext context,
    double avgRating,
    int totalRatings,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Star icons
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            return Icon(
              starValue <= avgRating ? Icons.star : Icons.star_outline,
              size: 16,
              color: colorScheme.primary,
            );
          }),
        ),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),

        // Rating text
        Text(
          avgRating.toStringAsFixed(1),
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),

        // Total count
        Text(
          '($totalRatings)',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedRating(
    BuildContext context,
    double avgRating,
    int totalRatings,
    List<RatingModel> ratingModels,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with average rating
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spaceM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Rating',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Row(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                      Icon(
                        Icons.star,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalRatings ${totalRatings == 1 ? 'Rating' : 'Ratings'}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  _buildRatingDistribution(context, ratingModels),
                ],
              ),
            ],
          ),
        ),
        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

        // Individual ratings
        Text(
          'Reviews',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

        // Ratings list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ratingModels.length > 5 ? 5 : ratingModels.length,
          separatorBuilder: (context, index) => Divider(
            color: colorScheme.outline,
            height: AppDesignSystem.spaceM,
          ),
          itemBuilder: (context, index) {
            final rating = ratingModels[index];
            return _buildRatingCard(context, rating);
          },
        ),

        // View all button
        if (ratingModels.length > 5 && onViewAllPressed != null)
          Padding(
            padding: const EdgeInsets.only(top: AppDesignSystem.spaceM),
            child: Center(
              child: TextButton(
                onPressed: onViewAllPressed,
                child: const Text('View All Ratings'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingDistribution(
    BuildContext context,
    List<RatingModel> ratings,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Count ratings by star level
    final distribution = {
      5: ratings.where((r) => r.rating >= 4.8).length,
      4: ratings.where((r) => r.rating >= 3.0 && r.rating < 4.8).length,
      3: ratings.where((r) => r.rating >= 2.0 && r.rating < 3.0).length,
      2: ratings.where((r) => r.rating >= 1.0 && r.rating < 2.0).length,
      1: ratings.where((r) => r.rating < 1.0).length,
    };

    return Row(
      children: distribution.entries.map((entry) {
        final percentage = ratings.isEmpty ? 0.0 : (entry.value / ratings.length) * 100;
        return Tooltip(
          message: '${percentage.toStringAsFixed(0)}% ${entry.key}⭐',
          child: Container(
            width: 6,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: percentage > 0
                  ? colorScheme.primary.withValues(alpha: percentage / 100)
                  : colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingCard(BuildContext context, RatingModel rating) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with rating and date
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Stars
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                return Icon(
                  starValue <= rating.rating ? Icons.star : Icons.star_outline,
                  size: 14,
                  color: colorScheme.primary,
                );
              }),
            ),
            // Date
            Text(
              _formatDate(rating.createdAt),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),

        // Feedback
        if (rating.feedback != null && rating.feedback!.isNotEmpty)
          Text(
            rating.feedback!,
            style: textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }
}
