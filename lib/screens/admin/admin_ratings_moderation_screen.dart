import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminRatingsModerationScreen extends StatefulWidget {
  const AdminRatingsModerationScreen({super.key});

  @override
  State<AdminRatingsModerationScreen> createState() =>
      _AdminRatingsModerationScreenState();
}

class _AdminRatingsModerationScreenState
    extends State<AdminRatingsModerationScreen> {
  late Stream<QuerySnapshot> _ratingsStream;
  String _filterStatus = 'all'; // 'all', 'flagged', 'pending'

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    if (_filterStatus == 'flagged') {
      _ratingsStream = FirebaseFirestore.instance
          .collection('ratings')
          .where('isFlagged', isEqualTo: true)
          .orderBy('flaggedAt', descending: true)
          .snapshots();
    } else {
      _ratingsStream = FirebaseFirestore.instance
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Rating Moderation',
        variant: AppBarVariant.primary,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
            child: Padding(
              padding: AppDesignSystem.paddingSymmetric(vertical: AppDesignSystem.spaceM),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('All Ratings'),
                      selected: _filterStatus == 'all',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _filterStatus = 'all';
                            _initializeStream();
                          });
                        }
                      },
                    ),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                    FilterChip(
                      label: Text('Flagged'),
                      selected: _filterStatus == 'flagged',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _filterStatus = 'flagged';
                            _initializeStream();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Ratings list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _ratingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppDesignSystem.primary(context),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: AppDesignSystem.paddingL,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: colorScheme.error,
                          ),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                          Text(
                            'Error loading ratings',
                            style: AppDesignSystem.titleMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                          Text(
                            snapshot.error.toString(),
                            style: AppDesignSystem.bodySmall(context).copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allRatings = snapshot.data?.docs ?? [];

                if (allRatings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: AppDesignSystem.paddingL,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_outline,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                          Text(
                            _filterStatus == 'flagged'
                                ? 'No flagged ratings'
                                : 'No ratings to moderate',
                            style: AppDesignSystem.titleMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceL),
                  itemCount: allRatings.length,
                  itemBuilder: (context, index) {
                    final ratingDoc = allRatings[index];
                    final ratingData =
                        ratingDoc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: AppDesignSystem.spaceM,
                      ),
                      child: _buildRatingCard(context, ratingDoc.id, ratingData),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(
    BuildContext context,
    String ratingId,
    Map<String, dynamic> ratingData,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFlagged = ratingData['isFlagged'] ?? false;
    final isApproved = ratingData['isApproved'] ?? false;
    
    // Validate rating data
    final ratingValue = ratingData['rating'] as num?;
    if (ratingValue == null) {
      debugPrint('❌ ERROR: Rating data missing for moderation ${ratingData['id']}');
      return AppCard(
        padding: AppDesignSystem.paddingM,
        child: Text('Unable to load rating data',
          style: AppDesignSystem.labelLarge(context).copyWith(
            color: Colors.red,
          ),
        ),
      );
    }
    final rating = ratingValue.toDouble();
    final feedback = ratingData['feedback'] as String? ?? '';
    final raterId = ratingData['raterId'] as String? ?? '';
    final raterType = ratingData['raterType'] as String? ?? '';
    final ratedUserId = ratingData['ratedUserId'] as String? ?? '';
    final ratedUserType = ratingData['ratedUserType'] as String? ?? '';
    final jobId = ratingData['jobId'] as String? ?? '';
    final flagReason = ratingData['flagReason'] as String?;
    final createdAt = ratingData['createdAt'] as Timestamp?;

    return AppCard(
      padding: AppDesignSystem.paddingM,
      elevation: 4,
      variant: SurfaceVariant.elevated,
      borderRadius: AppDesignSystem.borderRadiusM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating badge
              Container(
                padding: AppDesignSystem.paddingSymmetric(
                  horizontal: AppDesignSystem.spaceS,
                  vertical: AppDesignSystem.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: _getRatingColor(rating).withValues(alpha: 0.1),
                  borderRadius: AppDesignSystem.borderRadiusS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: _getRatingColor(rating),
                    ),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                    Text(
                      '${rating.toStringAsFixed(1)}/5',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getRatingColor(rating),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Status badges
              if (!isApproved && !isFlagged)
                Container(
                  padding: AppDesignSystem.paddingSymmetric(
                    horizontal: AppDesignSystem.spaceS,
                    vertical: AppDesignSystem.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.brandYellow.withValues(alpha: 0.1),
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                  child: Text(
                    'PENDING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppDesignSystem.brandYellow,
                    ),
                  ),
                ),
              if (isApproved && !isFlagged)
                Container(
                  padding: AppDesignSystem.paddingSymmetric(
                    horizontal: AppDesignSystem.spaceS,
                    vertical: AppDesignSystem.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.brandGreen.withValues(alpha: 0.1),
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                  child: Text(
                    'APPROVED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppDesignSystem.brandGreen,
                    ),
                  ),
                ),
              if (isFlagged)
                Container(
                  padding: AppDesignSystem.paddingSymmetric(
                    horizontal: AppDesignSystem.spaceS,
                    vertical: AppDesignSystem.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: AppDesignSystem.borderRadiusS,
                  ),
                  child: Text(
                    'FLAGGED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          // Info
          _buildInfoRow(context, 'From:', '$raterType: $raterId'),
          _buildInfoRow(context, 'To:', '$ratedUserType: $ratedUserId'),
          _buildInfoRow(context, 'Job:', jobId),
          _buildInfoRow(
            context,
            'Date:',
            createdAt != null ? timeago.format(createdAt.toDate()) : 'Unknown',
          ),
          if (isFlagged && flagReason != null)
            _buildInfoRow(
              context,
              'Flag Reason:',
              flagReason,
              isError: true,
            ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          // Feedback
          Container(
            padding: AppDesignSystem.paddingM,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: AppDesignSystem.borderRadiusS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feedback:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                Text(
                  feedback.isNotEmpty ? feedback : '(No feedback)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          // Action buttons - All ratings show flag and delete (all are approved by default now)
          Row(
            children: [
              Expanded(
                child: StandardButton(
                  label: 'Flag',
                  type: StandardButtonType.secondary,
                  icon: Icons.flag,
                  onPressed: () {
                    _showFlagDialog(context, ratingId);
                  },
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Expanded(
                child: StandardButton(
                  label: 'Delete',
                  type: StandardButtonType.danger,
                  icon: Icons.delete,
                  onPressed: () {
                    _deleteRating(context, ratingId);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: AppDesignSystem.paddingSymmetric(vertical: AppDesignSystem.spaceXS),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isError ? colorScheme.error : colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return AppDesignSystem.brandGreen;
    if (rating >= 3.0) return AppDesignSystem.brandYellow;
    if (rating >= 2.0) return AppDesignSystem.brandYellow;
    return AppDesignSystem.errorColor(context);
  }

  void _showFlagDialog(BuildContext context, String ratingId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Rating'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Why are you flagging this rating?',
              style: AppDesignSystem.bodyMedium(context),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusS,
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusS,
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusS,
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          StandardButton(
            label: 'Cancel',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context),
          ),
          StandardButton(
            label: 'Flag',
            type: StandardButtonType.secondary,
            onPressed: () {
              _flagRating(context, ratingId, reasonController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _flagRating(
    BuildContext context,
    String ratingId,
    String reason,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('ratings')
          .doc(ratingId)
          .update({
            'isFlagged': true,
            'flagReason': reason,
            'flaggedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      SnackbarHelper.showSuccess(this.context, 'Rating flagged successfully');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(this.context, 'Error flagging rating: $e');
    }
  }

  Future<void> _deleteRating(BuildContext context, String ratingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rating'),
        content: const Text('Are you sure you want to delete this rating?'),
        actions: [
          StandardButton(
            label: 'Cancel',
            type: StandardButtonType.text,
            onPressed: () => Navigator.pop(context, false),
          ),
          StandardButton(
            label: 'Delete',
            type: StandardButtonType.danger,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('ratings')
          .doc(ratingId)
          .delete();

      if (!mounted) return;
      SnackbarHelper.showSuccess(this.context, '✗ Rating deleted');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(this.context, 'Error deleting rating: $e');
    }
  }
}
