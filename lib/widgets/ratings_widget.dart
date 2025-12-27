import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/models/rating_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:timeago/timeago.dart' as timeago;

class RatingsWidget extends StatefulWidget {
  final String userId;
  final String userType; // 'jobSeeker' or 'company'
  final bool isOwnProfile;

  const RatingsWidget({
    super.key,
    required this.userId,
    required this.userType,
    this.isOwnProfile = false,
  });

  @override
  State<RatingsWidget> createState() => _RatingsWidgetState();
}

class _RatingsWidgetState extends State<RatingsWidget> {
  late Stream<QuerySnapshot> _ratingsStream;
  double _averageRating = 0.0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    _initializeRatingsStream();
  }

  void _initializeRatingsStream() {
    _ratingsStream = FirebaseFirestore.instance
        .collection('ratings')
        .where('ratedUserId', isEqualTo: widget.userId)
        .where('ratedUserType', isEqualTo: widget.userType)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  double _calculateAverageRating(List<RatingModel> ratings) {
    if (ratings.isEmpty) return 0.0;
    final sum = ratings.fold<double>(0, (sum, rating) => sum + rating.rating);
    return sum / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: _ratingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppCard(
            padding: AppDesignSystem.paddingM,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return AppCard(
            padding: AppDesignSystem.paddingM,
            child: Text('Error loading ratings: ${snapshot.error}'),
          );
        }

        final ratings = snapshot.data?.docs
                .map((doc) => RatingModel.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id))
                .toList() ??
            [];

        _averageRating = _calculateAverageRating(ratings);
        _totalRatings = ratings.length;

        if (ratings.isEmpty) {
          return AppCard(
            padding: AppDesignSystem.paddingM,
            child: Column(
              children: [
                Icon(
                  Icons.star_outline,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Text(
                  'No ratings yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary
            AppCard(
              padding: AppDesignSystem.paddingM,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average Rating',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                        Row(
                          children: [
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary,
                              ),
                            ),
                            AppDesignSystem.horizontalSpace(
                                AppDesignSystem.spaceS),
                            _buildStarRating(_averageRating),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: AppDesignSystem.paddingM,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDesignSystem.radiusM),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_totalRatings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'rating${_totalRatings != 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

            // Recent Ratings (show first 3)
            Text(
              'Recent Reviews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

            ...ratings.take(3).map((rating) => _buildRatingCard(
                  context,
                  rating,
                )),

            // See All Ratings Button
            if (ratings.length > 3)
              Padding(
                padding: EdgeInsets.only(top: AppDesignSystem.spaceM),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllRatingsScreen(
                            userId: widget.userId,
                            userType: widget.userType,
                            userName: '', // Will be loaded in screen
                          ),
                        ),
                      );
                    },
                    child: Text('See All ${_totalRatings.toString()} Reviews'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        final fillPercentage = (rating - index).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Stack(
            children: [
              Icon(
                Icons.star,
                color: Colors.grey.withValues(alpha: 0.3),
                size: 16,
              ),
              ClipRect(
                clipper: _StarClipper(fillPercentage),
                child: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRatingCard(BuildContext context, RatingModel rating) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: AppDesignSystem.paddingM,
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.raterType == 'company'
                          ? 'Company Review'
                          : 'Job Seeker Review',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    _buildStarRating(rating.rating),
                  ],
                ),
              ),
              Text(
                timeago.format(rating.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (rating.feedback != null && rating.feedback!.isNotEmpty) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Text(
              rating.feedback!,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (rating.jobTitle != null && rating.jobTitle!.isNotEmpty) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spaceS,
                vertical: AppDesignSystem.spaceXS,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
              ),
              child: Text(
                'Job: ${rating.jobTitle}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// All Ratings Screen
class AllRatingsScreen extends StatefulWidget {
  final String userId;
  final String userType;
  final String userName;

  const AllRatingsScreen({
    super.key,
    required this.userId,
    required this.userType,
    required this.userName,
  });

  @override
  State<AllRatingsScreen> createState() => _AllRatingsScreenState();
}

class _AllRatingsScreenState extends State<AllRatingsScreen> {
  late Stream<QuerySnapshot> _ratingsStream;

  @override
  void initState() {
    super.initState();
    _ratingsStream = FirebaseFirestore.instance
        .collection('ratings')
        .where('ratedUserId', isEqualTo: widget.userId)
        .where('ratedUserType', isEqualTo: widget.userType)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Reviews'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ratingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ratings = snapshot.data?.docs
                  .map((doc) => RatingModel.fromMap(
                      doc.data() as Map<String, dynamic>, doc.id))
                  .toList() ??
              [];

          if (ratings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: AppDesignSystem.spaceL),
                  Text('No reviews yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: AppDesignSystem.paddingM,
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index];
              return _buildRatingCard(context, rating);
            },
          );
        },
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context, RatingModel rating) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: AppDesignSystem.paddingM,
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.raterType == 'company'
                          ? 'Company Review'
                          : 'Job Seeker Review',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    _buildStarRating(rating.rating),
                  ],
                ),
              ),
              Text(
                timeago.format(rating.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (rating.feedback != null && rating.feedback!.isNotEmpty) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            Text(
              rating.feedback!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (rating.jobTitle != null && rating.jobTitle!.isNotEmpty) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spaceS,
                vertical: AppDesignSystem.spaceXS,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
              ),
              child: Text(
                'Job: ${rating.jobTitle}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        final fillPercentage = (rating - index).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Stack(
            children: [
              Icon(
                Icons.star,
                color: Colors.grey.withValues(alpha: 0.3),
                size: 16,
              ),
              ClipRect(
                clipper: _StarClipper(fillPercentage),
                child: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// Star Clipper for partial star fill
class _StarClipper extends CustomClipper<Rect> {
  final double fillPercentage;

  _StarClipper(this.fillPercentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fillPercentage, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) {
    return oldClipper.fillPercentage != fillPercentage;
  }
}
