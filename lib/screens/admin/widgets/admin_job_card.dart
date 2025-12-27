import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';

class AdminJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final String status;
  final VoidCallback onTap;

  const AdminJobCard({
    super.key,
    required this.job,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final jobTitle =
        job['title'] as String? ?? job['jobTitle'] as String? ?? 'Untitled Job';
    final employerName = job['name'] as String? ?? 'Unknown Employer';
    final category = job['category'] as String? ?? '';
    final type = job['type'] as String? ?? '';
    final budget = job['budget'] as String? ?? '';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      variant: SurfaceVariant.elevated,
      borderRadius: AppDesignSystem.borderRadiusM,
      onTap: onTap,
      padding: AppDesignSystem.paddingM,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDesignSystem.spaceM),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
            ),
            child: Icon(
              Icons.work,
              color: colorScheme.onSecondaryContainer,
              size: 24,
            ),
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (employerName.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Text(
                    employerName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (category.isNotEmpty || type.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  Row(
                    children: [
                      if (category.isNotEmpty)
                        Flexible(
                          child: Text(
                            category,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (category.isNotEmpty && type.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('•', style: textTheme.labelSmall),
                        ),
                      if (type.isNotEmpty)
                        Text(
                          type,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (budget.isNotEmpty)
                Text(
                  budget,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
