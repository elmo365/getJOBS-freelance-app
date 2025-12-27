import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class AdminJobStatisticsScreen extends StatefulWidget {
  const AdminJobStatisticsScreen({super.key});

  @override
  State<AdminJobStatisticsScreen> createState() =>
      _AdminJobStatisticsScreenState();
}

class _AdminJobStatisticsScreenState extends State<AdminJobStatisticsScreen> {
  late Stream<QuerySnapshot> _jobsStream;
  late Stream<QuerySnapshot> _ratingsStream;

  @override
  void initState() {
    super.initState();
    _jobsStream = FirebaseFirestore.instance.collection('jobs').snapshots();
    _ratingsStream =
        FirebaseFirestore.instance.collection('ratings').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Job Statistics',
        variant: AppBarVariant.primary,
      ),
      body: SingleChildScrollView(
        padding: AppDesignSystem.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Statistics
            StreamBuilder<QuerySnapshot>(
              stream: _jobsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final jobs = snapshot.data?.docs ?? [];
                final totalJobs = jobs.length;
                final completedJobs = jobs
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>)['status'] ==
                        'filled')
                    .length;
                final activeJobs = jobs
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>)['status'] ==
                        'active')
                    .length;
                final pendingJobs = jobs
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>)['status'] ==
                        'pending')
                    .length;

                int totalPositions = 0;
                int totalFilled = 0;
                for (var doc in jobs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalPositions +=
                      (data['positionsAvailable'] as int?) ?? 1;
                  totalFilled += (data['positionsFilled'] as int?) ?? 0;
                }

                final completionRate = totalPositions > 0
                    ? ((totalFilled / totalPositions) * 100).toStringAsFixed(1)
                    : '0.0';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    _buildStatCard(
                      context,
                      'Total Jobs',
                      '$totalJobs',
                      Icons.work,
                      colorScheme.primary,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Active',
                            '$activeJobs',
                            Icons.play_circle,
                            Colors.blue,
                          ),
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Completed',
                            '$completedJobs',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Pending',
                            '$pendingJobs',
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Completion Rate',
                            '$completionRate%',
                            Icons.trending_up,
                            colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                    AppCard(
                      padding: AppDesignSystem.paddingM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Position Statistics',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Positions',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  AppDesignSystem.verticalSpace(
                                      AppDesignSystem.spaceXS),
                                  Text(
                                    '$totalPositions',
                                    style: theme.textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Positions Filled',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  AppDesignSystem.verticalSpace(
                                      AppDesignSystem.spaceXS),
                                  Text(
                                    '$totalFilled',
                                    style: theme.textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remaining',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  AppDesignSystem.verticalSpace(
                                      AppDesignSystem.spaceXS),
                                  Text(
                                    '${totalPositions - totalFilled}',
                                    style: theme.textTheme.displaySmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            // Rating Statistics
            StreamBuilder<QuerySnapshot>(
              stream: _ratingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final ratings = snapshot.data?.docs ?? [];
                final totalRatings = ratings.length;
                final companyRatings = ratings
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>)['raterType'] ==
                        'company')
                    .length;
                final jobSeekerRatings = ratings
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>)['raterType'] ==
                        'jobSeeker')
                    .length;

                double averageRating = 0.0;
                if (ratings.isNotEmpty) {
                  double sum = 0;
                  int validRatings = 0;
                  for (var doc in ratings) {
                    final data = doc.data() as Map<String, dynamic>;
                    final rating = data['rating'] as num?;
                    if (rating != null) {
                      sum += rating.toDouble();
                      validRatings++;
                    } else {
                      // Skip invalid data points
                      debugPrint('⚠️ Warning: Invalid rating for ${data['ratedUserId']}');
                    }
                  }
                  // Only calculate average from valid ratings
                  averageRating = validRatings > 0 ? sum / validRatings : 0.0;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating Statistics',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    _buildStatCard(
                      context,
                      'Total Ratings',
                      '$totalRatings',
                      Icons.star,
                      Colors.amber,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Company Ratings',
                            '$companyRatings',
                            Icons.business,
                            colorScheme.primary,
                          ),
                        ),
                        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Job Seeker Ratings',
                            '$jobSeekerRatings',
                            Icons.person,
                            colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    AppCard(
                      padding: AppDesignSystem.paddingM,
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 48,
                            color: Colors.amber,
                          ),
                          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceL),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Average Rating',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              AppDesignSystem.verticalSpace(
                                  AppDesignSystem.spaceXS),
                              Text(
                                averageRating.toStringAsFixed(2),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 20,
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
