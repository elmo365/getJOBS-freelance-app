import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/models/interview_model.dart';
import 'package:freelance_app/services/interview_service.dart';

/// Interview Card Widget for Job Seekers - Displays interview details with employer information
/// Shows company/employer context, interview schedule, and actions the job seeker can take
class JobSeekerInterviewCard extends StatelessWidget {
  final InterviewModel interview;
  final bool isUpcoming;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onViewDetails;
  final VoidCallback? onReschedule;

  const JobSeekerInterviewCard({
    super.key,
    required this.interview,
    required this.isUpcoming,
    this.onAccept,
    this.onDecline,
    this.onViewDetails,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: SurfaceVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with Gradient Background and Employer Logo
          _buildHeader(context, colorScheme, textTheme),
          
          // Interview Details Section
          _buildDetailsSection(context, colorScheme, textTheme),

          // Meeting Medium Section (Video Call, Phone, In-Person)
          _buildMediumSection(context, colorScheme, textTheme),

          // Location and Meeting Link if available
          if (interview.location != null || interview.meetingLink != null)
            _buildLocationSection(context, colorScheme, textTheme),

          // Notes from employer if available
          if (interview.notes != null && interview.notes!.isNotEmpty)
            _buildNotesSection(context, colorScheme, textTheme),

          // Action Buttons based on status
          _buildActions(context),
        ],
      ),
    );
  }

  /// Header with gradient background, employer info, and status badge
  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: EdgeInsets.all(AppDesignSystem.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employer/Company Logo Placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
            child: Icon(
              Icons.business,
              color: colorScheme.secondary,
            ),
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          
          // Company/Job Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  interview.jobTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                Text(
                  'With ${interview.employerName}',
                  style: textTheme.bodySmall!.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spaceS,
              vertical: AppDesignSystem.spaceXS,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(context, interview.status)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
            ),
            child: Text(
              interview.status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _getStatusColor(context, interview.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Interview date and duration
  Widget _buildDetailsSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spaceM,
        vertical: AppDesignSystem.spaceM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scheduled Date
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Expanded(
                child: Text(
                  'Scheduled: ${InterviewService.formatForDisplay(interview.scheduledDate)}',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          
          // Duration
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                '${interview.durationMinutes} minutes',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Interview medium (video call, phone, in-person)
  Widget _buildMediumSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spaceM),
      child: Container(
        padding: EdgeInsets.all(AppDesignSystem.spaceM),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getMediumIcon(interview.medium),
              size: 20,
              color: colorScheme.primary,
            ),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interview Medium',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    _getMediumLabel(interview.medium),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Location and meeting link section
  Widget _buildLocationSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spaceM,
        vertical: AppDesignSystem.spaceS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (interview.location != null) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                Expanded(
                  child: Text(
                    interview.location!,
                    style: textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (interview.meetingLink != null) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Row(
              children: [
                Icon(
                  Icons.link,
                  size: 16,
                  color: colorScheme.primary,
                ),
                AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Meeting link: ${interview.meetingLink}'),
                        ),
                      );
                    },
                    child: Text(
                      interview.meetingLink ?? 'Meeting link',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Employer's notes/instructions for the interview
  Widget _buildNotesSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spaceM,
        vertical: AppDesignSystem.spaceS,
      ),
      child: Container(
        padding: EdgeInsets.all(AppDesignSystem.spaceS),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interview Notes:',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
            Text(
              interview.notes!,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Action buttons - varies based on interview status
  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppDesignSystem.spaceM),
      child: Column(
        children: [
          if (isUpcoming && interview.status == 'Scheduled') ...[
            // Not yet accepted - show accept/decline options
            StandardButton(
              label: 'Accept Interview',
              onPressed: onAccept,
              type: StandardButtonType.primary,
              icon: Icons.check_circle,
              fullWidth: true,
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            StandardButton(
              label: 'Decline Interview',
              onPressed: onDecline,
              type: StandardButtonType.danger,
              icon: Icons.close,
              fullWidth: true,
            ),
          ] else if (isUpcoming && interview.status == 'Accepted') ...[
            // Accepted - show reschedule/confirmation
            StandardButton(
              label: 'Prepare for Interview',
              onPressed: () {},
              type: StandardButtonType.primary,
              icon: Icons.school,
              fullWidth: true,
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            StandardButton(
              label: 'Reschedule',
              onPressed: onReschedule,
              type: StandardButtonType.secondary,
              icon: Icons.edit_calendar,
              fullWidth: true,
            ),
          ] else if (interview.status == 'Completed') ...[
            // Completed - show feedback/rating option
            StandardButton(
              label: 'View Feedback',
              onPressed: onViewDetails,
              type: StandardButtonType.secondary,
              icon: Icons.star,
              fullWidth: true,
            ),
          ] else ...[
            // Other statuses - view details
            StandardButton(
              label: 'View Details',
              onPressed: onViewDetails,
              type: StandardButtonType.secondary,
              icon: Icons.visibility,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue;
      case 'Accepted':
        return Colors.green;
      case 'Completed':
        return Colors.lightGreen;
      case 'Cancelled':
        return Colors.red;
      case 'Declined':
        return Colors.orange;
      case 'Ongoing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get medium icon
  IconData _getMediumIcon(String medium) {
    switch (medium.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'phone':
        return Icons.call;
      case 'in-person':
        return Icons.location_on;
      default:
        return Icons.chat;
    }
  }

  /// Get medium label
  String _getMediumLabel(String medium) {
    switch (medium.toLowerCase()) {
      case 'video':
        return 'Video Call';
      case 'phone':
        return 'Phone Call';
      case 'in-person':
        return 'In-Person Interview';
      default:
        return medium;
    }
  }
}
