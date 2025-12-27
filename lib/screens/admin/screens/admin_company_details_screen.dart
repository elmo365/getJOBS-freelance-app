import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/widgets/common/contact_action_row.dart';

class AdminCompanyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> company;
  final String docId;
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRevoke;
  final VoidCallback onReapprove;
  final VoidCallback onViewKyc;

  const AdminCompanyDetailsScreen({
    super.key,
    required this.company,
    required this.docId,
    required this.status,
    required this.onApprove,
    required this.onReject,
    required this.onRevoke,
    required this.onReapprove,
    required this.onViewKyc,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final companyName = company['company_name'] ?? 'Unknown Company';
    final regNumber = company['registration_number'] ?? 'N/A';
    final industry = company['industry'] ?? 'N/A';
    final email = company['email'] ?? 'N/A';
    final phone = company['phone_number'] ?? 'N/A';
    final address = company['address'] ?? 'N/A';
    final website = company['website'] ?? '';
    final description = company['company_description'] ?? 'No description';
    final contactPerson = company['name'] ?? 'N/A';
    final userImage = company['user_image'] ?? '';
    final createdAt = company['createdAt'] ?? company['created'];
    DateTime? created;
    if (createdAt != null) {
      if (createdAt is Timestamp) {
        created = createdAt.toDate();
      } else if (createdAt is String && createdAt.isNotEmpty) {
        try {
          created = DateTime.parse(createdAt);
        } catch (e) {
          created = null;
        }
      } else if (createdAt is DateTime) {
        created = createdAt;
      }
    }

    return Scaffold(
      appBar: AppAppBar(
        title: companyName,
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        userImage.isNotEmpty ? NetworkImage(userImage) : null,
                    child: userImage.isEmpty
                        ? Icon(Icons.business,
                            size: 40, color: colorScheme.primary)
                        : null,
                  ),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                        Text(
                          industry,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (created != null) ...[
                          AppDesignSystem.verticalSpace(
                              AppDesignSystem.spaceXS),
                          Text(
                            'Applied: ${DateFormat('MMM d, y').format(created)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

            // Details Section
            AppCard(
              padding: AppDesignSystem.paddingL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Information',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  _buildDetailRow(
                      context, 'Registration Number', regNumber, Icons.numbers),
                  _buildDetailRow(
                      context, 'Contact Person', contactPerson, Icons.person),
                  if (email != 'N/A' || phone != 'N/A') ...[
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    ContactActionRow(
                      email: email != 'N/A' ? email : null,
                      phoneNumber: phone != 'N/A' ? phone : null,
                      compact: false,
                    ),
                  ],
                  _buildDetailRow(
                      context, 'Address', address, Icons.location_on),
                  if (website.isNotEmpty)
                    _buildDetailRow(
                        context, 'Website', website, Icons.language),

                  const Divider(height: 32),

                  Text(
                    'Company Description',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),

                  // KYC Docs
                  StandardButton(
                    label: 'View KYC Documents',
                    type: StandardButtonType.secondary,
                    onPressed: onViewKyc,
                    icon: Icons.folder_open,
                    fullWidth: true,
                  ),

                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),

                  // Action Buttons
                  if (status == 'pending')
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
                            onPressed: onReject,
                            icon: Icons.close,
                          ),
                        ),
                      ],
                    ),

                  if (status == 'approved')
                    StandardButton(
                      label: 'Revoke Approval',
                      type: StandardButtonType.secondary,
                      onPressed: onRevoke,
                      icon: Icons.block,
                      fullWidth: true,
                    ),

                  if (status == 'rejected') ...[
                    if (company['rejectionReason'] != null) ...[
                      Container(
                        padding: AppDesignSystem.paddingM,
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: AppDesignSystem.borderRadiusM,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejection Reason:',
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceS),
                            Text(
                              company['rejectionReason'],
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    ],
                    StandardButton(
                      label: 'Re-approve',
                      type: StandardButtonType.success,
                      onPressed: onReapprove,
                      icon: Icons.check_circle,
                      fullWidth: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
