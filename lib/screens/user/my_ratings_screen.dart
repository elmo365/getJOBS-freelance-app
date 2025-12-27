import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/models/rating_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key});

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  final _authService = FirebaseAuthService();
  late Stream<QuerySnapshot> _ratingsStream;

  @override
  void initState() {
    super.initState();
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      _ratingsStream = FirebaseFirestore.instance
          .collection('ratings')
          .where('raterId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // Fallback empty stream if not logged in
      _ratingsStream = const Stream.empty() as Stream<QuerySnapshot>;
    }
  }

  Future<void> _deleteRating(String ratingId) async {
    try {
      await FirebaseFirestore.instance.collection('ratings').doc(ratingId).delete();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Rating deleted');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error deleting rating: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: 'My Ratings', variant: AppBarVariant.primary),
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
                  .map((doc) => RatingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
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
                  Text('You have not submitted any ratings yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: AppDesignSystem.paddingM,
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index];
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
                                rating.raterType == 'company' ? 'Company Review' : 'Job Seeker Review',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                              Row(children: [
                                Text(
                                  rating.rating.toStringAsFixed(1),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                                // Simple inline stars
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < rating.rating ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timeago.format(rating.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                            Chip(
                              label: Text('Approved'),
                              backgroundColor: Colors.green.withValues(alpha: 0.1),
                              labelStyle: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    if (rating.feedback != null && rating.feedback!.isNotEmpty) ...[
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      Text(rating.feedback!, style: theme.textTheme.bodyMedium),
                    ],
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete rating'),
                                content: Text('Are you sure you want to delete this rating?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _deleteRating(rating.ratingId);
                            }
                          },
                          icon: Icon(Icons.delete_outline),
                          label: Text('Delete'),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
