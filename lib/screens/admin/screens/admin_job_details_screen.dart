import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/contact_action_row.dart';

class AdminJobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onApprove;
  final Function(String) onReject;

  const AdminJobDetailsScreen({
    super.key,
    required this.job,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final jobTitle =
        job['title'] as String? ?? job['jobTitle'] as String? ?? 'Untitled Job';
    final employerName = job['name'] as String? ?? 'Unknown Employer';
    final email =
        job['email'] as String? ?? job['contactEmail'] as String? ?? 'N/A';
    final phone =
        job['phone'] as String? ?? job['contactPhone'] as String? ?? 'N/A';

    final category = job['category'] as String? ?? 'N/A';
    final type = job['type'] as String? ?? 'N/A';
    final budget = job['budget'] as String? ?? 'N/A';
    final duration = job['duration'] as String? ?? 'N/A';
    final experience = job['experienceLevel'] as String? ?? 'N/A';
    final location = job['location'] as String? ?? 'Remote';

    final description =
        job['description'] as String? ?? 'No description provided';
    final requirements = job['requirements'] as String? ?? '';

    final createdAt = job['createdAt'] ?? job['postedAt'];
    DateTime? posted;
    if (createdAt != null) {
      if (createdAt is Timestamp) {
        posted = createdAt.toDate();
      } else if (createdAt is String && createdAt.isNotEmpty) {
        try {
          posted = DateTime.parse(createdAt);
        } catch (e) {
          posted = null;
        }
      } else if (createdAt is DateTime) {
        posted = createdAt;
      }
    }

    return Scaffold(
      appBar: AppAppBar(
        title: 'Job Details',
        variant: AppBarVariant.primary,
      ),
      body: SingleChildScrollView(
        padding: AppDesignSystem.paddingL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            AppCard(
              padding: AppDesignSystem.paddingL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: AppDesignSystem.paddingM,
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: AppDesignSystem.borderRadiusM,
                        ),
                        child: Icon(
                          Icons.work,
                          size: 32,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jobTitle,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceXS),
                            Text(
                              employerName,
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _JobTag(
                          label: category,
                          icon: Icons.category,
                          color: colorScheme.tertiary),
                      _JobTag(
                          label: type,
                          icon: Icons.schedule,
                          color: colorScheme.secondary),
                      _JobTag(
                          label: location,
                          icon: Icons.location_on,
                          color: colorScheme.primary),
                    ],
                  ),
                ],
              ),
            ),

            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

            // Job Details
            AppCard(
              padding: AppDesignSystem.paddingL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Overview',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

                  _buildDetailRow(
                      context, 'Budget', budget, Icons.attach_money),
                  _buildDetailRow(context, 'Duration', duration, Icons.timer),
                  _buildDetailRow(context, 'Experience Level', experience,
                      Icons.trending_up),
                  if (posted != null)
                    _buildDetailRow(
                        context,
                        'Posted On',
                        DateFormat('MMM d, y').format(posted),
                        Icons.calendar_today),

                  const Divider(height: 32),

                  if (description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Text(description),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                  ],

                  if (requirements.isNotEmpty) ...[
                    Text(
                      'Requirements',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Text(requirements),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                  ],

                  const Divider(height: 32),

                  Text(
                    'Contact Information',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  if (email != 'N/A' || phone != 'N/A')
                    ContactActionRow(
                      email: email != 'N/A' ? email : null,
                      phoneNumber: phone != 'N/A' ? phone : null,
                      compact: false,
                    )
                  else
                    const Text('No contact information available'),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: StandardButton(
                          label: 'Approve',
                          type: StandardButtonType.success,
                          onPressed: onApprove,
                          icon: Icons.check,
                        ),
                      ),
                      AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                      Expanded(
                        child: StandardButton(
                          label: 'Reject',
                          type: StandardButtonType.danger,
                          onPressed: () => _showRejectDialog(context),
                          icon: Icons.close,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Inappropriate content',
                border: OutlineInputBorder(
                  borderRadius: AppDesignSystem.borderRadiusS,
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
            label: 'Reject',
            type: StandardButtonType.danger,
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                // Ideally use a proper Snackbar or error handling here
                return;
              }
              Navigator.pop(context); // Close dialog
              onReject(reasonController.text.trim());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _JobTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty || label == 'N/A') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
