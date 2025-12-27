import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/models/interview_model.dart';
import 'package:freelance_app/services/interview_service.dart';

/// Interview Card Widget for Employers - Displays interview details with modern design pattern
/// Shows candidate information, interview schedule, and employer actions
/// Supports both upcoming and past interviews with conditional actions
class InterviewCard extends StatelessWidget {
  final InterviewModel interview;
  final bool isUpcoming;
  final bool hasConflict;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;
  final VoidCallback? onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const InterviewCard({
    super.key,
    required this.interview,
    required this.isUpcoming,
    required this.hasConflict,
    this.onReschedule,
    this.onCancel,
    this.onViewDetails,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: hasConflict ? SurfaceVariant.elevated : SurfaceVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with candidate info - Following Job Card Design Pattern
          _buildHeader(context, colorScheme, textTheme),

          // Interview Details Section (Date, Duration)
          _buildDetailsSection(context, colorScheme, textTheme),

          // Interview Medium Section (Video Call, Phone, In-Person)
          _buildMediumSection(context, colorScheme, textTheme),

          // Location and Meeting Link if available
          if (interview.location != null || interview.meetingLink != null)
            _buildLocationSection(context, colorScheme, textTheme),

          // Notes/Additional Info if available
          if (interview.notes != null && interview.notes!.isNotEmpty)
            _buildNotesSection(context, colorScheme, textTheme),

          // Action Buttons
          _buildActions(context),
        ],
      ),
    );
  }

  /// Header with gradient background, candidate info, and status badge
  /// Follows ModernJobCard design pattern with avatar, title, subtitle, status
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
          // Candidate Avatar - Placeholder with person icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person,
              color: colorScheme.primary,
            ),
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),

          // Candidate details - Name, Job Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  interview.candidateName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                Text(
                  interview.jobTitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status badge
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
              style: textTheme.labelSmall?.copyWith(
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

  /// Interview medium (video call, phone, in-person) with highlighted container
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
                  child: Text(
                    'Meeting Link Available',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
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

  /// Notes/Additional Information section
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
        padding: EdgeInsets.all(AppDesignSystem.spaceM),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Notes',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
            Text(
              interview.notes ?? '',
              style: textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Action buttons - Responsive based on interview status
  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spaceM,
        vertical: AppDesignSystem.spaceM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary action buttons
          if (isUpcoming) ...[
            // For upcoming interviews: Reschedule and Cancel
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (onReschedule != null)
                  Expanded(
                    child: StandardButton(
                      label: 'Reschedule',
                      onPressed: onReschedule,
                      type: StandardButtonType.secondary,
                      icon: Icons.edit_calendar,
                      fullWidth: true,
                    ),
                  ),
                if (onReschedule != null && onCancel != null)
                  SizedBox(width: AppDesignSystem.spaceS),
                if (onCancel != null)
                  Expanded(
                    child: StandardButton(
                      label: 'Cancel',
                      onPressed: onCancel,
                      type: StandardButtonType.danger,
                      icon: Icons.close,
                      fullWidth: true,
                    ),
                  ),
              ],
            ),
          ] else ...[
            // For past interviews: View Details
            if (onViewDetails != null)
              StandardButton(
                label: 'View Details',
                onPressed: onViewDetails,
                type: StandardButtonType.secondary,
                icon: Icons.visibility,
                fullWidth: true,
              ),
          ],

          // Secondary action buttons (Edit/Delete)
          if (onEdit != null || onDelete != null) ...[
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (onEdit != null)
                  Expanded(
                    child: StandardButton(
                      label: 'Edit',
                      onPressed: onEdit,
                      type: StandardButtonType.secondary,
                      icon: Icons.edit,
                      fullWidth: true,
                    ),
                  ),
                if (onEdit != null && onDelete != null)
                  SizedBox(width: AppDesignSystem.spaceS),
                if (onDelete != null)
                  Expanded(
                    child: StandardButton(
                      label: 'Delete',
                      onPressed: onDelete,
                      type: StandardButtonType.danger,
                      icon: Icons.delete_outline,
                      fullWidth: true,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return colorScheme.error;
      case 'declined':
        return Colors.orange;
      default:
        return colorScheme.primary;
    }
  }

  IconData _getMediumIcon(String medium) {
    switch (medium.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'phone':
        return Icons.phone;
      case 'in-person':
      case 'inperson':
      case 'in person':
        return Icons.location_on;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.video_call;
    }
  }

  String _getMediumLabel(String medium) {
    switch (medium.toLowerCase()) {
      case 'video':
        return 'Video Call';
      case 'phone':
        return 'Phone Call';
      case 'in-person':
      case 'inperson':
      case 'in person':
        return 'In-Person';
      case 'chat':
        return 'Chat/Messaging';
      default:
        return medium;
    }
  }
}
