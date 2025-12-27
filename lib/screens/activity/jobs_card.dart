import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/dialogs/job_deadline_dialog.dart';
import 'applicants.dart';
import 'details.dart';
import 'package:freelance_app/widgets/common/app_card.dart';

class Job extends StatelessWidget {
  final String jobID;
  final String jobTitle;
  final String uploadedBy;
  final String contactName;
  final String contactImage;
  final DateTime date;
  final String type;
  final DateTime? deadline; // Job closing deadline
  final VoidCallback? onUpdate; // Callback to refresh after deadline changes
  final int positionsAvailable; // Number of positions available
  final int positionsFilled; // Number of positions filled
  final String? jobStatus; // Job status (pending, active, filled, etc.)

  const Job({
    super.key,
    required this.jobTitle,
    required this.date,
    required this.type,
    required this.jobID,
    required this.uploadedBy,
    required this.contactName,
    required this.contactImage,
    this.deadline,
    this.onUpdate,
    this.positionsAvailable = 1,
    this.positionsFilled = 0,
    this.jobStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AppDesignSystem.verticalSpace(6),
        AppCard(
          padding: EdgeInsets.zero,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => (type == 'taken' || false)
                    ? const Details()
                    : ApplicantsApp(
                        jobId: jobID,
                      ),
              ),
            );
          },
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    jobTitle,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Position indicator badge
                if (positionsAvailable > 1 || positionsFilled > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: jobStatus == 'filled'
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                      border: Border.all(
                        color: jobStatus == 'filled'
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      jobStatus == 'filled'
                          ? 'Filled'
                          : '$positionsFilled/$positionsAvailable',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: jobStatus == 'filled'
                            ? Colors.green
                            : Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppDesignSystem.verticalSpace(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'company/Name: $contactName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                    Text(DateFormat.yMMMd().add_jm().format(date)),
                  ],
                ),
                // Add expiry widget for company jobs
                if (type == 'posted' && deadline != null) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  JobExpiryWidget(
                    jobId: jobID,
                    jobTitle: jobTitle,
                    companyId: uploadedBy,
                    deadline: deadline,
                    onUpdate: onUpdate ?? () {},
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
