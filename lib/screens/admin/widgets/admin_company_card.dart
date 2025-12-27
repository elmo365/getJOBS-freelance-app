import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';

class AdminCompanyCard extends StatelessWidget {
  final Map<String, dynamic> company;
  final String docId;
  final String status;
  final VoidCallback onTap;

  const AdminCompanyCard({
    super.key,
    required this.company,
    required this.docId,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final companyName =
        company['company_name'] ?? company['name'] ?? 'Unknown Company';
    final regNumber = company['registration_number'] ?? 'N/A';
    final industry = company['industry'] ?? 'N/A';
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

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      variant: SurfaceVariant.elevated,
      borderRadius: AppDesignSystem.borderRadiusM,
      onTap: onTap,
      padding: AppDesignSystem.paddingM,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage:
                userImage.isNotEmpty ? NetworkImage(userImage) : null,
            child: userImage.isEmpty
                ? Icon(Icons.business, color: colorScheme.primary)
                : null,
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName.isNotEmpty
                      ? companyName
                      : 'Company Name Not Available',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (industry.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    industry,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (regNumber.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    'Reg: $regNumber',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (created != null) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    'Applied: ${DateFormat('MMM d, y').format(created)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
