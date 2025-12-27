import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freelance_app/models/rating_model.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';

/// Rating submission screen for post-completion ratings
/// Supports both employer and job seeker rating workflows
class RatingSubmissionScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String ratedUserId; // User being rated
  final String ratedUserName; // Name of the person being rated
  final String? ratedUserImage;
  final String raterType; // 'company' or 'jobSeeker'

  const RatingSubmissionScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.ratedUserId,
    required this.ratedUserName,
    this.ratedUserImage,
    required this.raterType,
  }) : super();

  @override
  State<RatingSubmissionScreen> createState() => _RatingSubmissionScreenState();
}

class _RatingSubmissionScreenState extends State<RatingSubmissionScreen> {
  final _notificationService = NotificationService();
  final _feedbackController = TextEditingController();

  double _rating = 4.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0.0) {
      SnackbarHelper.showError(context, 'Please select a rating');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      final ratingId = FirebaseFirestore.instance.collection('ratings').doc().id;

      final ratingModel = RatingModel(
        ratingId: ratingId,
        raterId: currentUser.uid,
        raterType: widget.raterType,
        ratedUserId: widget.ratedUserId,
        ratedUserType: widget.raterType == 'company' ? 'jobSeeker' : 'company',
        jobId: widget.jobId,
        jobTitle: widget.jobTitle,
        rating: _rating,
        feedback: _feedbackController.text.trim().isNotEmpty
            ? _feedbackController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('ratings')
          .doc(ratingId)
          .set(ratingModel.toMap());

      // Send notification to rated user
      await _notificationService.sendNotification(
        userId: widget.ratedUserId,
        type: 'rating_received',
        title: 'You received a ${_rating.toStringAsFixed(1)} ⭐ rating!',
        body: widget.raterType == 'company'
            ? 'The employer rated your work: ${_feedbackController.text.isNotEmpty ? '"${_feedbackController.text}"' : 'No comment'}'
            : 'The job seeker rated you: ${_feedbackController.text.isNotEmpty ? '"${_feedbackController.text}"' : 'No comment'}',
        data: {
          'jobId': widget.jobId,
          'ratingId': ratingId,
          'rating': _rating.toString(),
        },
        sendEmail: true,
      );

      if (!mounted) return;

      SnackbarHelper.showSuccess(
        context,
        'Rating submitted successfully! Thank you for your feedback.',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        'Error submitting rating: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  if (widget.ratedUserImage != null && widget.ratedUserImage!.isNotEmpty)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(widget.ratedUserImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                  // Rating title
                  Text(
                    'Rate ${widget.ratedUserName}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),

                  // Job title
                  Text(
                    'For: ${widget.jobTitle}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

            // Star rating section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How would you rate this experience?',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                  // Star selector
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1.0;
                        final isFilled = starValue <= _rating;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _rating = starValue);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              isFilled ? Icons.star : Icons.star_outline,
                              size: 40,
                              color: isFilled ? colorScheme.primary : colorScheme.outlineVariant,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                  // Rating text display
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _rating.toStringAsFixed(1),
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' / 5.0 • ',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: _getRatingLabel(_rating),
                            style: textTheme.bodyMedium?.copyWith(
                              color: _getRatingColor(colorScheme),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

            // Feedback section
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share your feedback (optional)',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                  // Feedback text field
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: widget.raterType == 'company'
                          ? 'Tell us about the candidate\'s performance, work quality, communication, and professionalism...'
                          : 'Tell us about your experience with the employer, job clarity, communication, and work environment...',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    style: textTheme.bodyMedium,
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),

                  // Character count
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${_feedbackController.text.length}/500',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: StandardButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    type: StandardButtonType.secondary,
                  ),
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                Expanded(
                  child: StandardButton(
                    label: _isSubmitting ? 'Submitting...' : 'Submit Rating',
                    onPressed: _isSubmitting ? null : _submitRating,
                    type: StandardButtonType.primary,
                  ),
                ),
              ],
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating < 2.0) return 'Poor';
    if (rating < 3.0) return 'Fair';
    if (rating < 4.0) return 'Good';
    if (rating < 4.8) return 'Very Good';
    return 'Excellent';
  }

  Color _getRatingColor(ColorScheme colorScheme) {
    if (_rating < 2.0) return colorScheme.error;
    if (_rating < 3.0) return colorScheme.tertiary;
    if (_rating < 4.0) return colorScheme.secondary;
    if (_rating < 4.8) return colorScheme.primary;
    return colorScheme.primary;
  }
}
